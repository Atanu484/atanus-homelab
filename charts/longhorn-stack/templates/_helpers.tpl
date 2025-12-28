{{- define "longhorn-stack.namespaceName" -}}
{{- default "longhorn-system" .Values.namespace.name -}}
{{- end -}}
