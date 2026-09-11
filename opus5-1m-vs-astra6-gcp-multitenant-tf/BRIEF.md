# Build brief — multi-tenant, two-sided platform on GCP (Terraform)

> This is the complete brief. The run is **autonomous and non-interactive**: nobody
> will answer questions. Where the brief is silent, decide, and record the decision
> and its reasoning in the README. Your choices are part of the deliverable.

## The task

Write the Terraform for the infrastructure of a **multi-tenant platform with a
consumer side and a provider side** on Google Cloud. Tenants are businesses that
onboard onto the platform; each tenant has its own consumers (end users) and its
own providers (the businesses' suppliers or staff). The platform operator runs one
codebase for all tenants.

Deliver a working Terraform root in this repository. It must be **plannable by a
person who has a GCP project, a billing account and a state bucket**, with no
edits other than filling in variables.

## Hard constraints

1. **Terraform only.** HCL for the Google provider. No wrapper CLI, no Terragrunt,
   no shell scripts as the primary interface. Pin `required_version` and
   `required_providers` to explicit versions.
2. **Nothing is applied.** Do not run `terraform apply` or `terraform plan`. No GCP
   credentials are available and none may be assumed. The configuration must be
   correct without having been applied.
3. **Quality gate.** From the repository root, all of the following must succeed:
   ```
   terraform fmt -check -recursive
   terraform init -backend=false
   terraform validate
   tflint --recursive
   ```
   If you use multiple roots, every root must pass `init -backend=false` and
   `validate`.
4. **No secrets in the repo.** No credential values, no service-account key files,
   no secret payloads in `.tf`, `.tfvars`, or examples. Commit a `.gitignore` that
   keeps `.terraform/`, state files and local tfvars out of git.
5. **Do not push.** You may commit locally. The harness handles tags and remotes.

## Required outcomes

1. **Declarative tenant onboarding.** Adding a tenant is a **data change, not a code
   change**: a new entry in a variable, tfvars, YAML or JSON file, and nothing
   else. Ship at least **two example tenants** so the mechanism is visible.
2. **A stated and justified data-isolation model.** Choose how tenant data is kept
   apart. State the choice in the README and justify it against the alternatives
   you rejected, including the trade-offs you accepted.
3. **Two APIs as separate Cloud Run services**: a consumer-facing API and a
   provider-facing API. Container images may be placeholders. Decide and document
   who may invoke each service.
4. **Per-tenant service accounts with least-privilege IAM.** No primitive roles
   (`roles/owner`, `roles/editor`, `roles/viewer`). Every binding must be the
   narrowest role that does the job.
5. **Cloud SQL on private IP only.** No public database endpoint. Postgres or
   MySQL is your call.
6. **Secret Manager with per-tenant secret scoping.** A tenant's workload can read
   its own secrets and no other tenant's. No plaintext secret values anywhere.
7. **Remote GCS state backend with locking.** The bucket name is an input, not a
   hard-coded value.
8. **`dev`, `staging` and `prod` separable without copy-paste.** Environments must
   differ by configuration only; shared logic must exist once.
9. **Observability and cost.** Log sinks with per-tenant routing, and billing
   budget alerts. Thresholds and destinations are inputs.
10. **README.md** containing: an architecture overview, the rationale behind every
    open decision below, and a **tenant-onboarding runbook** a new operator can
    follow step by step.

## Deliberately left open — you decide, and you explain

- **Tenant boundary:** project-per-tenant, shared project with labels, or a
  hybrid.
- **Data isolation:** database-per-tenant, schema-per-tenant, or row-level
  security in a shared database.
- **Module decomposition and repository layout.**
- Region, network topology, naming convention, and anything else this brief does
  not fix.

## What "done" means

A reviewer can clone the repository, run the four quality-gate commands from the
root and see them all pass, open the README and find the architecture rationale
and the runbook, and trace each of the ten required outcomes to concrete
resources in the code rather than to a stub or a comment.
