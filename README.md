# AWS 3-Tier Highly Available Architecture via Terraform

![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Linux](https://img.shields.io/badge/Amazon_Linux_2023-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![MySQL](https://img.shields.io/badge/MySQL-005C84?style=for-the-badge&logo=mysql&logoColor=white)
![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)

## Introduzione al progetto
Questo repository contiene il codice completo per il provisioning di un'architettura AWS a tre livelli (Web, App e Data), interamente gestita tramite Terraform. L'obiettivo del progetto è dimostrare un approccio pratico e maturo all'Infrastructure as Code (IaC), andando oltre i concetti teorici per costruire un ambiente resiliente, sicuro e automatizzato.

Ho progettato questa infrastruttura tenendo a mente i pilastri dell'AWS Well-Architected Framework, concentrandomi in particolare sulla sicurezza del dato e sull'alta affidabilità dei servizi di calcolo.

## Architettura e scelte tecniche

L'ambiente cloud è stato strutturato per garantire isolamento e scalabilità:

* Networking e Alta Affidabilità: L'infrastruttura poggia su una VPC dedicata, divisa in 6 subnet che si estendono su 2 diverse Availability Zone. Questo previene disservizi in caso di guasti a un singolo data center. Il traffico in uscita dalle subnet private è gestito in sicurezza tramite un NAT Gateway con IP elastico.
* Calcolo e Scalabilità: Il traffico in ingresso viene intercettato da un Application Load Balancer (ALB) esposto su internet, che distribuisce in modo intelligente le richieste a un Auto Scaling Group di istanze EC2 (Amazon Linux 2023). In questo modo, il sistema può adattarsi dinamicamente al carico di lavoro.
* Database Isolato: Il livello dati è affidato ad Amazon RDS (MySQL). Per massimizzare la sicurezza, il database risiede in un DB Subnet Group strettamente privato, senza alcun IP pubblico assegnato, e con crittografia dei dati a riposo abilitata.
* Sicurezza a strati: Ho implementato una rigida segregazione del traffico tramite Security Group a cascata. L'esterno comunica solo con il Load Balancer, il quale a sua volta è l'unico autorizzato a parlare con le istanze EC2, che infine sono le uniche ad avere accesso al database. Inoltre, ho eliminato del tutto l'uso delle vulnerabili chiavi SSH, delegando l'accesso sicuro ai server al servizio AWS Systems Manager (SSM) tramite ruoli IAM dedicati.

## Struttura della repository

Il codice è organizzato in file separati per logica, seguendo le best practice di Terraform per favorire la leggibilità e la manutenzione:

* provider.tf: Configurazione del provider AWS.
* variables.tf: Definizione delle variabili di input (regione, blocchi CIDR, credenziali).
* network.tf: Risorse di rete (VPC, Subnet, Internet Gateway, NAT Gateway, tabelle di routing).
* security.tf: Definizione dei Security Group per il controllo degli accessi.
* database.tf: Configurazione dell'istanza RDS e del relativo gruppo di subnet.
* compute.tf: Ruoli IAM, Load Balancer, Launch Template e Auto Scaling Group.
* user_data.tftpl: Script Bash iniettato al lancio delle macchine per la configurazione del server web.
* outputs.tf: Esposizione dinamica dell'URL pubblico del Load Balancer e dell'endpoint del database.
* .gitignore: Configurazione per escludere file sensibili e file di stato dal controllo di versione.

## Automazione e bootstrap dinamico

Uno degli aspetti più interessanti del progetto è il processo di bootstrap. Al momento della creazione dell'infrastruttura, Terraform recupera dinamicamente l'endpoint del database RDS appena generato e lo inietta nello script Bash di configurazione.

Quando le istanze EC2 si avviano, installano il server web Apache, interrogano i metadati sicuri di AWS (tramite IMDSv2) per ottenere il proprio IP privato e generano una pagina HTML di conferma. Questa pagina dimostra non solo che il server è attivo, ma che è perfettamente consapevole della rete interna e connesso con successo al database isolato.

## Come avviare l'infrastruttura

Per testare questo progetto sul tuo ambiente AWS, assicurati di avere installato Terraform e configurato la AWS CLI con credenziali dotate di privilegi adeguati.

1. Clona questo repository sul tuo computer e inizializza Terraform:
   ```bash
   git clone https://github.com/Titovschi5/aws-terraform-progetto1.git
   cd aws-terraform-progetto1
   terraform init
   ```

2. Imposta le credenziali del database. Crea un file chiamato `terraform.tfvars` nella cartella principale (questo file è escluso dal tracciamento Git per motivi di sicurezza) e inserisci le tue variabili:
   ```hcl
   db_username = "admin"
   db_password = "SostituisciConUnaPasswordSicura123!"
   ```

3. Verifica il piano di esecuzione per controllare quali risorse verranno create:
   ```bash
   terraform plan
   ```

4. Avvia il provisioning:
   ```bash
   terraform apply
   ```

L'operazione richiederà circa 5-10 minuti, dovuti principalmente ai tempi di allocazione del database RDS. Al termine, Terraform stamperà a video un URL. Incollando quell'URL nel browser, potrai visualizzare la pagina web generata dai server che conferma il successo del deployment.

## Pulizia delle risorse

Per evitare costi imprevisti, specialmente se si utilizza il Free Tier di AWS, è essenziale smantellare l'infrastruttura una volta terminati i test. È possibile rimuovere in modo pulito tutte le risorse create tramite un unico comando:

```bash
terraform destroy
```

## Autore

**Tito Catalano**  
Junior Cloud & DevOps Engineer | AWS Certified Cloud Practitioner
* [Profilo LinkedIn](https://www.linkedin.com/in/titocatalano/)