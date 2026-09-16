# Future backend — reference architecture (not built, not deployed)

M6 Sudoku has **no backend today**. Storage is 100% local (`SharedPreferences`
via `StorageService`/`JsonStore`), and there are zero external integrations
(see `whatitis.md`). Nothing in this directory runs, is referenced by CI, or
is required for shipping the app as it exists now.

It exists because `CHANGELOG.md` lists **cloud sync** as a "Planned" feature,
and cloud sync is the one plausible future that would turn this from a pure
mobile/web client into something with an actual server to deploy, scale, and
monitor — i.e. the point where "Kubernetes" stops being a category error for
this project. This is a starting point for *that* day, not a task to do now.

## Recommended shape, if/when it's built

For the actual workload implied by "sync a player's puzzle progress and
statistics across devices" — small JSON blobs, low write volume, no heavy
compute — **Cloud Run (or an equivalent managed container platform)**, not
a Kubernetes cluster, is the right first move:

- Scales to zero between requests — this app's traffic is spiky/low-volume
  (people play in short bursts), not steady-state, so you'd pay for GKE
  control-plane and node overhead nearly all the time for no benefit.
- No cluster to patch, upgrade, or capacity-plan.
- Same container image works if it *does* later outgrow Cloud Run — export
  to GKE with the `k8s/` manifests in this directory as a starting point.

Reach for real Kubernetes only once there's a concrete reason Cloud Run
can't satisfy — e.g. multiple coordinated stateful services, custom
networking/service-mesh needs, or sustained enough load that container
orchestration control (node pools, bin-packing, custom autoscaling
policies) starts paying for itself. Don't build the cluster ahead of that
evidence.

## Contents

- `Dockerfile` — a generic multi-stage Node/Express *placeholder* showing
  the shape (build stage, slim runtime, non-root user, health endpoint).
  Swap the runtime for whatever the actual sync API ends up being written
  in.
- `k8s/` — minimal illustrative Deployment/Service/HPA manifests, for the
  GKE-outgrows-Cloud-Run scenario above. Not tuned, not production-hardened
  — a starting skeleton, not a copy-paste-and-ship artifact.
