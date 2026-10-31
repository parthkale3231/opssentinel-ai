{{- define "demostore.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "demostore.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "demostore.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "demostore.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | quote }}
app.kubernetes.io/name: {{ include "demostore.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: demostore
{{- end -}}

{{- define "demostore.selectorLabels" -}}
app.kubernetes.io/name: {{ include "demostore.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "demostore.apiSelectorLabels" -}}
app.kubernetes.io/name: {{ .Values.api.selectorName }}
{{- end -}}

{{- define "demostore.apiPodLabels" -}}
{{ include "demostore.apiSelectorLabels" . }}
app.kubernetes.io/part-of: demostore
{{- end -}}

{{- define "demostore.postgresSelectorLabels" -}}
app.kubernetes.io/name: {{ .Values.postgres.selectorName }}
{{- end -}}

{{- define "demostore.postgresPodLabels" -}}
{{ include "demostore.postgresSelectorLabels" . }}
app.kubernetes.io/part-of: demostore
{{- end -}}

{{- define "demostore.postgresName" -}}
{{- printf "%s-postgres" (include "demostore.fullname" .) -}}
{{- end -}}

{{- define "demostore.apiName" -}}
{{- printf "%s-api" (include "demostore.fullname" .) -}}
{{- end -}}

{{- define "demostore.secretName" -}}
{{- if .Values.postgres.auth.existingSecret -}}
{{- .Values.postgres.auth.existingSecret -}}
{{- else -}}
{{- printf "%s-db-secret" (include "demostore.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "demostore.configName" -}}
{{- printf "%s-api-config" (include "demostore.fullname" .) -}}
{{- end -}}

{{- define "demostore.migrationName" -}}
{{- printf "%s-migrations" (include "demostore.fullname" .) -}}
{{- end -}}
