{{- define "override_config_map" }}

apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ template "quiz-ci.fullname" . }}
data:
  config.xml: |-
    <?xml version='1.0' encoding='UTF-8'?>
    <hudson>
      <disabledAdministrativeMonitors/>
      <version>{{ .Values.Master.ImageTag }}</version>
      <numExecutors>0</numExecutors>
      <mode>NORMAL</mode>
      <useSecurity>{{ .Values.Master.UseSecurity }}</useSecurity>
      <authorizationStrategy class="hudson.security.FullControlOnceLoggedInAuthorizationStrategy">
        <denyAnonymousReadAccess>true</denyAnonymousReadAccess>
      </authorizationStrategy>
      <securityRealm class="hudson.security.LegacySecurityRealm"/>
      <disableRememberMe>false</disableRememberMe>
      <projectNamingStrategy class="jenkins.model.ProjectNamingStrategy$DefaultProjectNamingStrategy"/>
      <workspaceDir>${JENKINS_HOME}/workspace/${ITEM_FULLNAME}</workspaceDir>
      <buildsDir>${ITEM_ROOTDIR}/builds</buildsDir>
      <markupFormatter class="hudson.markup.EscapedMarkupFormatter"/>
      <jdks/>
      <viewsTabBar class="hudson.views.DefaultViewsTabBar"/>
      <myViewsTabBar class="hudson.views.DefaultMyViewsTabBar"/>
      <clouds>
        <org.csanchez.jenkins.plugins.kubernetes.KubernetesCloud plugin="kubernetes@{{ template "jenkins.kubernetes-version" . }}">
          <name>kubernetes</name>
          <templates>
{{- if .Values.Agent.Enabled }}
            <org.csanchez.jenkins.plugins.kubernetes.PodTemplate>
              <inheritFrom></inheritFrom>
              <name>default</name>
              <instanceCap>2147483647</instanceCap>
              <idleMinutes>0</idleMinutes>
              <label>{{ .Release.Name }}-{{ .Values.Agent.Component }}</label>
              <nodeSelector>
                {{- $local := dict "first" true }}
                {{- range $key, $value := .Values.Agent.NodeSelector }}
                  {{- if not $local.first }},{{- end }}
                  {{- $key }}={{ $value }}
                  {{- $_ := set $local "first" false }}
                {{- end }}</nodeSelector>
                <nodeUsageMode>NORMAL</nodeUsageMode>
              <volumes>
{{- range $index, $volume := .Values.Agent.volumes }}
                <org.csanchez.jenkins.plugins.kubernetes.volumes.{{ $volume.type }}Volume>
{{- range $key, $value := $volume }}{{- if not (eq $key "type") }}
                  <{{ $key }}>{{ $value }}</{{ $key }}>
{{- end }}{{- end }}
                </org.csanchez.jenkins.plugins.kubernetes.volumes.{{ $volume.type }}Volume>
{{- end }}
              </volumes>
              <containers>
                <org.csanchez.jenkins.plugins.kubernetes.ContainerTemplate>
                  <name>jnlp</name>
                  <image>{{ .Values.Agent.Image }}:{{ .Values.Agent.ImageTag }}</image>
{{- if .Values.Agent.Privileged }}
                  <privileged>true</privileged>
{{- else }}
                  <privileged>false</privileged>
{{- end }}
                  <alwaysPullImage>{{ .Values.Agent.AlwaysPullImage }}</alwaysPullImage>
                  <workingDir>/home/jenkins</workingDir>
                  <command></command>
                  <args>${computer.jnlpmac} ${computer.name}</args>
                  <ttyEnabled>false</ttyEnabled>
                  <resourceRequestCpu>{{.Values.Agent.Cpu}}</resourceRequestCpu>
                  <resourceRequestMemory>{{.Values.Agent.Memory}}</resourceRequestMemory>
                  <resourceLimitCpu>{{.Values.Agent.Cpu}}</resourceLimitCpu>
                  <resourceLimitMemory>{{.Values.Agent.Memory}}</resourceLimitMemory>
                  <envVars>
                    <org.csanchez.jenkins.plugins.kubernetes.ContainerEnvVar>
                      <key>JENKINS_URL</key>
                      <value>http://{{ template "jenkins.fullname" . }}:{{.Values.Master.ServicePort}}{{ default "" .Values.Master.JenkinsUriPrefix }}</value>
                    </org.csanchez.jenkins.plugins.kubernetes.ContainerEnvVar>
                  </envVars>
                </org.csanchez.jenkins.plugins.kubernetes.ContainerTemplate>
              </containers>
              <envVars/>
              <annotations/>
{{- if .Values.Agent.ImagePullSecret }}
              <imagePullSecrets>
                <org.csanchez.jenkins.plugins.kubernetes.PodImagePullSecret>
                  <name>{{ .Values.Agent.ImagePullSecret }}</name>
                </org.csanchez.jenkins.plugins.kubernetes.PodImagePullSecret>
              </imagePullSecrets>
{{- else }}
              <imagePullSecrets/>
{{- end }}
              <nodeProperties/>
            </org.csanchez.jenkins.plugins.kubernetes.PodTemplate>
{{- end -}}
          </templates>
          <serverUrl>https://kubernetes.default</serverUrl>
          <skipTlsVerify>false</skipTlsVerify>
          <namespace>{{ .Release.Namespace }}</namespace>
          <jenkinsUrl>http://{{ template "jenkins.fullname" . }}:{{.Values.Master.ServicePort}}{{ default "" .Values.Master.JenkinsUriPrefix }}</jenkinsUrl>
          <jenkinsTunnel>{{ template "jenkins.fullname" . }}-agent:50000</jenkinsTunnel>
          <containerCap>10</containerCap>
          <retentionTimeout>5</retentionTimeout>
          <connectTimeout>0</connectTimeout>
          <readTimeout>0</readTimeout>
        </org.csanchez.jenkins.plugins.kubernetes.KubernetesCloud>
      </clouds>
      <quietPeriod>5</quietPeriod>
      <scmCheckoutRetryCount>0</scmCheckoutRetryCount>
      <views>
        <hudson.model.AllView>
          <owner class="hudson" reference="../../.."/>
          <name>All</name>
          <filterExecutors>false</filterExecutors>
          <filterQueue>false</filterQueue>
          <properties class="hudson.model.View$PropertyList"/>
        </hudson.model.AllView>
      </views>
      <primaryView>All</primaryView>
      <slaveAgentPort>50000</slaveAgentPort>
      <disabledAgentProtocols>
{{- range .Values.Master.DisabledAgentProtocols }}
        <string>{{ . }}</string>
{{- end }}
      </disabledAgentProtocols>
      <label></label>
{{- if .Values.Master.CSRF.DefaultCrumbIssuer.Enabled }}
      <crumbIssuer class="hudson.security.csrf.DefaultCrumbIssuer">
{{- if .Values.Master.CSRF.DefaultCrumbIssuer.ProxyCompatability }}
        <excludeClientIPFromCrumb>true</excludeClientIPFromCrumb>
{{- end }}
      </crumbIssuer>
{{- end }}
      <nodeProperties/>
      <globalNodeProperties/>
      <noUsageStatistics>true</noUsageStatistics>
    </hudson>
{{- if .Values.Master.ScriptApproval }}
  scriptapproval.xml: |-
    <?xml version='1.0' encoding='UTF-8'?>
    <scriptApproval plugin="script-security@1.27">
      <approvedScriptHashes/>
      <approvedSignatures>
{{- range $key, $val := .Values.Master.ScriptApproval }}
        <string>{{ $val }}</string>
{{- end }}
      </approvedSignatures>
      <aclApprovedSignatures/>
      <approvedClasspathEntries/>
      <pendingScripts/>
      <pendingSignatures/>
      <pendingClasspathEntries/>
    </scriptApproval>
{{- end }}
  jenkins.CLI.xml: |-
    <?xml version='1.1' encoding='UTF-8'?>
    <jenkins.CLI>
{{- if .Values.Master.CLI }}
      <enabled>true</enabled>
{{- else }}
      <enabled>false</enabled>
{{- end }}
    </jenkins.CLI>
  apply_config.sh: |-
    mkdir -p /usr/share/jenkins/ref/secrets/;
    echo "false" > /usr/share/jenkins/ref/secrets/slave-to-master-security-kill-switch;
    cp -n /var/jenkins_config/config.xml /var/jenkins_home;
    cp -n /var/jenkins_config/jenkins.CLI.xml /var/jenkins_home;
{{- if .Values.Master.InstallPlugins }}
    # Install missing plugins
    cp /var/jenkins_config/plugins.txt /var/jenkins_home;
    rm -rf /usr/share/jenkins/ref/plugins/*.lock
    /usr/local/bin/install-plugins.sh `echo $(cat /var/jenkins_home/plugins.txt)`;
    # Copy plugins to shared volume
    cp -n /usr/share/jenkins/ref/plugins/* /var/jenkins_plugins;
{{- end }}
{{- if .Values.Master.ScriptApproval }}
    cp -n /var/jenkins_config/scriptapproval.xml /var/jenkins_home/scriptApproval.xml;
{{- end }}
{{- if .Values.Master.InitScripts }}
    mkdir -p /var/jenkins_home/init.groovy.d/;
    cp -n /var/jenkins_config/*.groovy /var/jenkins_home/init.groovy.d/
{{- end }}
{{- if .Values.Master.CredentialsXmlSecret }}
    cp -n /var/jenkins_credentials/credentials.xml /var/jenkins_home;
{{- end }}
{{- if .Values.Master.SecretsFilesSecret }}
    cp -n /var/jenkins_secrets/* /usr/share/jenkins/ref/secrets;
{{- end }}
{{- if .Values.Master.Jobs }}
    for job in $(ls /var/jenkins_jobs); do
      mkdir -p /var/jenkins_home/jobs/$job
      cp -n /var/jenkins_jobs/$job /var/jenkins_home/jobs/$job/config.xml
    done
{{- end }}
    mkdir -p /var/jenkins_home/init.groovy.d/;
    cp -n /var/jenkins_config/initjobs.groovy /var/jenkins_home/init.groovy.d/
    cp -n /var/jenkins_config/initplugins.groovy /var/jenkins_home/init.groovy.d/

  initplugins.groovy: |-
    import jenkins.model.*
    import hudson.util.*
    import java.net.URL
    import org.jenkinsci.plugins.github.config.*

    // configure github plugin
    url = new URL('http','{{ .Values.Master.HostName }}', 80, '/github-webhook/')
    def pluginConfig = Jenkins.instance.getExtensionList(GitHubPluginConfig.class)[0]
    GitHubServerConfig serverConfig = new GitHubServerConfig('github-token')
    pluginConfig.setConfigs([serverConfig])
    pluginConfig.setOverrideHookUrl(true)
    pluginConfig.setHookUrl(url)
    pluginConfig.save()

  initjobs.groovy: |-
    import jenkins.model.*
    import hudson.util.*
    import javaposse.jobdsl.dsl.DslScriptLoader
    import javaposse.jobdsl.plugin.JenkinsJobManagement

    def pattern = ~/job.*\.groovy/
    new File("/var/jenkins_config/").eachDirRecurse { dir ->
            dir.eachFileMatch(pattern) {    file ->
              def jobManagement = new JenkinsJobManagement(System.out, [:], new File('.'))
              new DslScriptLoader(jobManagement).runScript(file.text)
          } 
    } 

{{ $repo := .Values.global.github.repo }}
{{ $admin := .Values.global.github.admin }}
{{- range $val := .Values.global.jobs}}
  job.{{ $val.name }}.groovy: |-
    pipelineJob('{{ $val.name }}') {
      definition {
        cpsScm {
          scm {
            git {
                remote {
                    github('{{ $repo }}')
                    credentials('github-username')
                }
                branch('*/master')
            }
          }
          triggers {
            githubPush()
          }
          scriptPath('{{ $val.jenkinsFile }}')
        }
      }
    }
{{- end }}

{{- range $key, $val := .Values.Master.InitScripts }}
  init{{ $key }}.groovy: |-
{{ $val | indent 4 }}
{{- end }}
  plugins.txt: |-
{{- if .Values.Master.InstallPlugins }}
{{- range $index, $val := .Values.Master.InstallPlugins }}
{{ $val | indent 4 }}
{{- end }}
{{- end }} 

{{- end -}}