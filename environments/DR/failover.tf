resource "google_storage_bucket" "scripts_bucket" {
  name          = "${local.prefix}-scripts-bucket"
  project       = module.gcp_project.project_id
  location      = var.gcp_region
  force_destroy = false
  
  versioning {
    enabled = true
  }
  
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_object" "database_failover" {
  bucket  = google_storage_bucket.scripts_bucket.name
  name    = "database_failover.sh"
  content = <<-EOF
#!/bin/bash

TEST_MODE=$${1:-false}

if [ "\$TEST_MODE" == "true" ]; then
  echo "Esecuzione in modalità test - nessuna promozione reale del database"
  gcloud sql instances describe ${google_sql_database_instance.replica.name} \
    --project=${module.gcp_project.project_id}
  exit 0
fi

echo "Avvio processo di failover database..."

gcloud sql instances promote-replica ${google_sql_database_instance.replica.name} \
  --project=${module.gcp_project.project_id} \
  --quiet

echo "Attesa per la promozione del database..."
while true; do
  STATUS=$(gcloud sql instances describe ${google_sql_database_instance.replica.name} \
    --project=${module.gcp_project.project_id} \
    --format="value(state)")
  
  if [ "$STATUS" == "RUNNABLE" ]; then
    break
  fi
  
  echo "Database in stato: $STATUS, attesa continua..."
  sleep 10
done

echo "Database promosso con successo a primario"

echo "Failover del database completato con successo" | mail -s "DR Database Failover Completato" ${var.alert_email}
EOF
}

resource "google_storage_bucket_object" "kubernetes_failover" {
  bucket  = google_storage_bucket.scripts_bucket.name
  name    = "kubernetes_failover.sh"
  content = <<-EOF
#!/bin/bash

TEST_MODE=$${1:-false}

echo "Avvio processo di failover Kubernetes..."

gcloud container clusters get-credentials ${module.gcp_kubernetes.cluster_name} \
  --region=${var.gcp_region} \
  --project=${module.gcp_project.project_id}

NODES_READY=$(kubectl get nodes -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' | grep -c "True")
echo "Nodi pronti nel cluster: $NODES_READY"

if [ "\$TEST_MODE" == "true" ]; then
  echo "Esecuzione in modalità test - nessuna promozione reale del cluster"
  kubectl get deployments --all-namespaces
  exit 0
fi

echo "Scaling applicazioni critiche..."
CRITICAL_APPS=("api-gateway" "auth-service" "core-service" "database-service")

for app in "\${CRITICAL_APPS}"; do

  if kubectl get deployment \$app -n production &> /dev/null; then
    kubectl scale deployment \$app -n production --replicas=3
    echo "Deployment \$app scalato a 3 repliche"
  else
    echo "Deployment \$app non trovato"
  fi
done

echo "Aggiornamento configurazione DNS..."

echo "Failover Kubernetes completato"
echo "Failover Kubernetes completato" | mail -s "DR Kubernetes Failover Completato" ${var.alert_email}
EOF
}

resource "google_storage_bucket_object" "complete_failover" {
  bucket  = google_storage_bucket.scripts_bucket.name
  name    = "complete_failover.sh"
  content = <<-EOF
#!/bin/bash

TEST_MODE=$${1:-false}
START_TIME=$(date +%s)

echo "======== AVVIO FAILOVER AMBIENTE DR ========"
echo "Data e ora inizio: $(date)"
echo "Modalità test: \$TEST_MODE"

echo "STEP 1: Failover Database..."
$(dirname "$0")/database_failover.sh \$TEST_MODE
DB_STATUS=$?

if [ $DB_STATUS -ne 0 ]; then
  echo "ERRORE: Failover database fallito con codice $DB_STATUS"
  echo "Failover ambiente DR fallito durante il failover database" | mail -s "ERRORE: DR Failover Fallito" ${var.alert_email}
  exit 1
fi

echo "STEP 2: Failover Kubernetes..."
$(dirname "$0")/kubernetes_failover.sh \$TEST_MODE
K8S_STATUS=$?

if [ $K8S_STATUS -ne 0 ]; then
  echo "ERRORE: Failover Kubernetes fallito con codice $K8S_STATUS"
  echo "Failover ambiente DR fallito durante il failover Kubernetes" | mail -s "ERRORE: DR Failover Fallito" ${var.alert_email}
  exit 1
fi

echo "STEP 3: Aggiornamento configurazione di rete..."
if [ "\$TEST_MODE" != "true" ]; then

  gcloud compute firewall-rules update allow-all-to-dr \
    --project=${module.gcp_project.project_id} \
    --allow=tcp:1-65535,udp:1-65535,icmp
fi

echo "STEP 4: Verifica finale dello stato..."
FINAL_CHECK=0

if gcloud sql instances describe ${google_sql_database_instance.replica.name} \
  --project=${module.gcp_project.project_id} | grep -q "RUNNABLE"; then
  echo "Database disponibile: OK"
else
  echo "Database non disponibile: ERRORE"
  FINAL_CHECK=1
fi

if kubectl get nodes | grep -q "Ready"; then
  echo "Cluster Kubernetes disponibile: OK"
else
  echo "Cluster Kubernetes non disponibile: ERRORE"
  FINAL_CHECK=1
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo "Durata totale del failover: $DURATION secondi"
echo "======== FAILOVER AMBIENTE DR COMPLETATO ========"

if [ $FINAL_CHECK -eq 0 ]; then
  SUBJECT="DR Failover Completato con Successo"
  MESSAGE="Il failover dell'ambiente DR è stato completato con successo in $DURATION secondi."
else
  SUBJECT="DR Failover Completato con Avvisi"
  MESSAGE="Il failover dell'ambiente DR è stato completato in $DURATION secondi, ma sono presenti alcuni avvisi. Verifica lo stato dell'ambiente."
fi

echo "$MESSAGE" | mail -s "$SUBJECT" ${var.alert_email}

exit $FINAL_CHECK
EOF
}

resource "google_storage_bucket" "function_bucket" {
  name          = "${local.prefix}-function-bucket"
  location      = var.gcp_region
  project       = module.gcp_project.project_id
  force_destroy = true
}

resource "google_storage_bucket_object" "function_source" {
  name   = "function-source.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = data.archive_file.failover_function.output_path
}

data "archive_file" "failover_function" {
  type        = "zip"
  output_path = "/tmp/function-source.zip"
  
  source {
    content  = <<-EOF
const {Storage} = require('@google-cloud/storage');
const {exec} = require('child_process');
const storage = new Storage();

exports.triggerFailover = async (req, res) => {

  const testMode = req.body.testMode === true;
  const secret = req.body.secret || '';
  
  if (secret !== process.env.AUTH_SECRET) {
    console.error('Errore di autenticazione');
    res.status(401).send('Non autorizzato');
    return;
  }
  
  console.log(`Avvio failover in modalità test: ${testMode}`);
  
  try {
    
    const bucketName = '${google_storage_bucket.scripts_bucket.name}';
    const fileName = 'complete_failover.sh';
    const localPath = '/tmp/complete_failover.sh';
    
    await storage.bucket(bucketName).file(fileName).download({
      destination: localPath
    });
    
    await execCommand('chmod +x ' + localPath);
    
    const cmdOutput = await execCommand(`${localPath} ${testMode}`);
    console.log('Output del comando di failover:', cmdOutput);
    
    res.status(200).send({
      status: 'success',
      message: 'Failover avviato con successo',
      testMode: testMode,
      output: cmdOutput
    });
  } catch (err) {
    console.error('Errore durante il failover:', err);
    res.status(500).send({
      status: 'error',
      message: 'Errore durante il failover',
      error: err.toString()
    });
  }
};

function execCommand(cmd) {
  return new Promise((resolve, reject) => {
    exec(cmd, (error, stdout, stderr) => {
      if (error) {
        reject(`Errore di esecuzione: ${error.message}`);
        return;
      }
      if (stderr) {
        console.warn(`Warning: ${stderr}`);
      }
      resolve(stdout);
    });
  });
}
EOF
    filename = "index.js"
  }
  
  source {
    content  = <<-EOF
{
  "name": "failover-function",
  "version": "1.0.0",
  "description": "Cloud Function per attivare failover ambiente DR",
  "main": "index.js",
  "dependencies": {
    "@google-cloud/storage": "^6.0.0"
  },
  "engines": {
    "node": "16"
  }
}
EOF
    filename = "package.json"
  }
}

resource "google_cloudfunctions_function" "failover_function" {
  name        = "dr-failover-trigger"
  project     = module.gcp_project.project_id
  region      = var.gcp_region
  description = "Funzione per attivare il failover dell'ambiente DR"
  
  runtime               = "nodejs16"
  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.function_bucket.name
  source_archive_object = google_storage_bucket_object.function_source.name
  trigger_http          = true
  entry_point           = "triggerFailover"
  
  environment_variables = {
    AUTH_SECRET = "REPLACE_WITH_SECURE_SECRET"
  }
  
  service_account_email = module.gcp_iam.service_account_email
  
  depends_on = [
    google_storage_bucket_object.function_source
  ]
}

resource "google_cloudfunctions_function_iam_member" "function_invoker" {
  project        = module.gcp_project.project_id
  region         = var.gcp_region
  cloud_function = google_cloudfunctions_function.failover_function.name
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:${module.gcp_iam.service_account_email}"
}

resource "google_cloud_scheduler_job" "failover_test_scheduler" {
  name        = "monthly-failover-test"
  project     = module.gcp_project.project_id
  region      = var.gcp_region
  description = "Test mensile del processo di failover"
  schedule    = "0 8 1 * *"  
  time_zone   = "Europe/Rome"
  
  http_target {
    uri         = google_cloudfunctions_function.failover_function.https_trigger_url
    http_method = "POST"
    
    headers = {
      "Content-Type" = "application/json"
    }
    
    body = base64encode(jsonencode({
      "testMode": true,
      "secret": "REPLACE_WITH_SECURE_SECRET"
    }))
    
    oidc_token {
      service_account_email = module.gcp_iam.service_account_email
    }
  }
}

resource "google_storage_bucket_object" "dr_documentation" {
  bucket  = google_storage_bucket.scripts_bucket.name
  name    = "DR_PROCEDURES.md"
  content = <<-EOF

Questo documento descrive le procedure di Disaster Recovery (DR) per l'ambiente ${var.project_name}.

- Database SQL (Azure & GCP)
- Cluster Kubernetes (Azure & GCP)
- Reti e Connettività
- Storage e Dati

Il failover automatico può essere attivato tramite:
1. Cloud Function: \`${google_cloudfunctions_function.failover_function.https_trigger_url}\`
2. Richiesta HTTP con credenziali appropriate

Per eseguire un failover manuale:
1. Accedere al bastion host DR
2. Eseguire: \`gs://${google_storage_bucket.scripts_bucket.name}/complete_failover.sh\`

Vengono eseguiti test automatici mensili. I report vengono inviati a: ${var.alert_email}

- RTO (Recovery Time Objective): 15 minuti
- RPO (Recovery Point Objective): 5 minuti per database, 15 minuti per altri dati

- Email: ${var.alert_email}
- Canale Slack: #${var.slack_channel}

Dopo il failover, verificare:
1. Accesso ai database
2. Funzionalità dei cluster Kubernetes
3. Routing del traffico corretto
4. Funzionalità delle applicazioni business-critical

Le procedure di failback devono essere eseguite quando l'ambiente di produzione torna operativo.
EOF
}