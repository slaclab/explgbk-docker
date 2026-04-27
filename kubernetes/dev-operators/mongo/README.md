# MongoDB Operator

Percona Operator for MongoDB installed via `helm template` + `kubectl-slice` + kustomize
for the `dev` watch namespace, deployed into the `psmdb-operator` namespace.

## Prerequisites

- `helm` — Helm CLI
- `kubectl-slice` — [github.com/patrickdappollonio/kubectl-slice](https://github.com/patrickdappollonio/kubectl-slice)
- `kubectl` with kustomize support

## Files

| File | Description |
|---|---|
| `ns.yaml` | Namespace definition (`psmdb-operator`) |
| `resources/` | Auto-generated manifests from `helm template` via `kubectl-slice` |
| `mongo-operator-dev-rbac.yaml` | Cross-namespace Role/RoleBinding granting operator access to `dev` namespace |
| `mongo-operator-patch.yaml` | Kustomize patch — sets `WATCH_NAMESPACE=dev` |
| `kustomization.yaml` | Composes resources and applies namespace + patches |
| `Makefile` | Operator lifecycle targets |

## Notes

The Percona CRD is too large for a normal `kubectl apply`. Use server-side apply:

```
make -C kubernetes/dev-operators/mongo apply
```

## Makefile targets

```
make update   # Re-generate resources/ from helm template + kubectl-slice
make apply    # kubectl apply --server-side --force-conflicts -k .
make diff     # kubectl diff --server-side -k .
make dump     # kubectl kustomize . (render to stdout)
```
