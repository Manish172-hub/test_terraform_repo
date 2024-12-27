FROM tomcat:8.0.20-jre8
# Dummy text to test 
COPY /var/lib/jenkins/workspace/docker_terr/target/myweb*.war  /usr/local/tomcat/webapps/myweb.war
