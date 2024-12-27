FROM tomcat:8.0.20-jre8
 
COPY /var/lib/jenkins/workspace/docker_terr/target/myweb*.war  /usr/local/tomcat/webapps/myweb.war
