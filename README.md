# Learn from Log4Shell
## 2022-10-04 DevOpsDays Houston

If you want to try some SBOM creation yourself:

1) install syft on your laptop/desktop: https://github.com/anchore/syft
2) install grype on your laptop/desktop: https://github.com/anchore/grype

If you have access to a jenkins instance, you can fork this repo and create a new pipeline project using the Jenkinsfile in your fork (you don't need to fork but I recommend it so you can tweak the Dockerfile and Jenkinsfile).

You can also just copy the Dockerfile and build it locally.

After you've created a few SBOMs, you can try a few of the following:

1) how many SBOMs are in the archive?
```
jenkins:~ # find ${JENKINS_HOME} -regex '.*cyclonedx-sbom.json$'
/var/jenkins_home/jobs/2022-devopsdays-houston/jobs/lab2/builds/1/archive/lab2:1-cyclonedx-sbom.json
/var/jenkins_home/jobs/2022-devopsdays-houston/jobs/lab2/builds/2/archive/lab2:2-cyclonedx-sbom.json
/var/jenkins_home/jobs/2022-devopsdays-houston/jobs/lab2/builds/3/archive/lab2:3-cyclonedx-sbom.json
/var/jenkins_home/jobs/2022-devopsdays-houston/jobs/lab4/builds/1/archive/lab4:1-cyclonedx-sbom.json
/var/jenkins_home/jobs/2022-devopsdays-houston/jobs/lab4/builds/2/archive/lab4:2-cyclonedx-sbom.json
...
```
Or, you can just count them:
```
jenkins:~ # find ${JENKINS_HOME} -regex '.*cyclonedx-sbom.json$' | wc -l
124
```

2) Find all SBOMs (cycloneDX format) that contain any log4j variant.

The jq filter here selects SBOMs that have a items in the "components" array with a .name containing "log4j" and then outputs the name of the image (i.e. the repository/tag as recorded in the SBOM), the "version" (i.e. the image digest recorded in the SBOM), and then the name and version of the log4j package:
```
jenkins:~ # find . -regex '.*cyclonedx-sbom.json$' -exec jq -r '(.metadata.component.name) + " " + (.metadata.component.version) + " " + (.components[] | select (.name|contains("log4j")) | "\(.name) \(.version)")' {} \;
lab2:1 sha256:bee2f4c8c5065bfcc3ff623d969856b73997353272c8f0e9d55e3b5bba222601 log4j-core 2.14.1
lab2:2 sha256:f4a7dca7597e92089861f8d46b0d0310c92003a1db5bf91c3d67f38969e594a3 log4j-core 2.15.0
lab2:3 sha256:6a7c2b1a0a2695adc96c1f9ddc8b975d90192846f2a7555dd2958fa4ec1ec828 log4j-core 2.17.1
...
```

3. Only find log4j packages that are vulnerable.

this just adds another "select" to the jq filter to get package versions below 2.17.1 (all log4shell issues were patched by this release).
```
jenkins:~ # find . -regex '.*cyclonedx-sbom.json$' -exec jq -r '(.metadata.component.name) + " " + (.metadata.component.version) + " " + (.components[] | select (.name|contains("log4j")) | select (.version < "2.17.1") | "\(.name) \(.version)")' {} \;
lab2:1 sha256:bee2f4c8c5065bfcc3ff623d969856b73997353272c8f0e9d55e3b5bba222601 log4j-core 2.14.1
lab2:2 sha256:f4a7dca7597e92089861f8d46b0d0310c92003a1db5bf91c3d67f38969e594a3 log4j-core 2.15.0
lab4:1 sha256:0e2988c10f592adb4a8d85bc9433b8ef38ce1918e3895115c71bc3ef3b3c0890 log4j-core 2.14.1
lab4:2 sha256:c9a0c9df88af4b5582915078654d327ad38186d033fdf3e7519214ae98257456 log4j-core 2.15.0
```

4. (TO DO) pipe all sboms into grype for CVE matching
