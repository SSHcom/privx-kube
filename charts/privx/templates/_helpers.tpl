{{/*
Expand the name of the chart.
*/}}
{{- define "privx.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "privx.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "privx.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "privx.labels" -}}
helm.sh/chart: {{ include "privx.chart" . }}
{{ include "privx.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "privx.selectorLabels" -}}
app.kubernetes.io/name: {{ include "privx.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "privx.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "privx.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- /*
Creates a space separated list of FQDNS from the list of ingress hosts
*/ -}}
{{- define "getHostnamesWithSpaces" -}}
{{-   $hostnames := "" }}
{{-   range . }}
{{-     $hostname := .host | toString }}
{{-     if ne $hostnames "" }}
{{-       $hostnames = printf "%s %s" $hostnames $hostname }}
{{-     else }}
{{-       $hostnames = $hostname }}
{{-     end }}
{{-   end }}
{{-   $hostnames }}
{{- end }}

{{- /*
Creates a comma separated list of FQDNS from the list of ingress hosts
It takes an optional argument to ignore a host from the list at a particular
index.
*/ -}}
{{- define "getHostnamesWithCommas" -}}
{{-   $hostnames := "" }}
{{-   $ignoreIndex := -1 }}
{{-   if gt (len .) 1 }}
{{-     $ignoreIndex = index . 1 }}
{{-   end }}
{{-   range $index, $item := index . 0 }}
{{-     if ne $index $ignoreIndex -}}
{{-       $hostname := $item.host | toString }}
{{-       if ne $hostnames "" }}
{{-         $hostnames = printf "%s,%s" $hostnames $hostname }}
{{-       else }}
{{-         $hostnames = $hostname }}
{{-       end }}
{{-     end }}
{{-   end }}
{{-   $hostnames }}
{{- end }}
