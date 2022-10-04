# Learn from Log4Shell
## 2022-10-04 DevOpsDays 

If you want to try some SBOM creation yourself:

1) install syft on your laptop/desktop: https://github.com/anchore/syft
2) install grype on your laptop/desktop: https://github.com/anchore/grype

If you have access to a jenkins instance, you can fork this repo and create a new pipeline project using the Jenkinsfile in your fork (you don't need to fork but I recommend it so you can tweak the Dockerfile and Jenkinsfile).

I've also included a docker-compose.yml file you can use to spin up a simple jenkins instance on your local machine with Docker Desktop or similar (instructions at the bottom of this readme).

You can also just copy the Dockerfile and build it locally.

## 0) Create some SBOMs 
If you're using the jenkinsfile, SBOMs will be created immediately after each image build.  If you're just interactively noodling, you can create the SBOMs with a command like this:
```
# syft --output json=${IMAGE}-syft-sbom.json --output table=${IMAGE}-syft-sbom.txt --output spdx-json=${IMAGE}-spdx-sbom.json --output cyclonedx-json=${IMAGE}-cyclonedx-sbom.json ${IMAGE} 
```
This will create SBOMs in CycloneDX, SPDX, and Syft SBOMs in JSON format along with a simple text table SBOM.

After you've created a few SBOMs, you can try a few of the following:

## 1) how many SBOMs are in the archive?
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

## 2) Find all SBOMs (cycloneDX format) that contain any log4j variant.

The jq filter here selects SBOMs that have a items in the "components" array with a .name containing "log4j" and then outputs the name of the image (i.e. the repository/tag as recorded in the SBOM), the "version" (i.e. the image digest recorded in the SBOM), and then the name and version of the log4j package:
```
jenkins:~ # find . -regex '.*cyclonedx-sbom.json$' -exec jq -r '(.metadata.component.name) + " " + (.metadata.component.version) + " " + (.components[] | select (.name|contains("log4j")) | "\(.name) \(.version)")' {} \;
lab2:1 sha256:bee2f4c8c5065bfcc3ff623d969856b73997353272c8f0e9d55e3b5bba222601 log4j-core 2.14.1
lab2:2 sha256:f4a7dca7597e92089861f8d46b0d0310c92003a1db5bf91c3d67f38969e594a3 log4j-core 2.15.0
lab2:3 sha256:6a7c2b1a0a2695adc96c1f9ddc8b975d90192846f2a7555dd2958fa4ec1ec828 log4j-core 2.17.1
...
```

## 3. Only find log4j packages that are vulnerable.

this just adds another "select" to the jq filter to get package versions below 2.17.1 (all log4shell issues were patched by this release).
```
jenkins:~ # find . -regex '.*cyclonedx-sbom.json$' -exec jq -r '(.metadata.component.name) + " " + (.metadata.component.version) + " " + (.components[] | select (.name|contains("log4j")) | select (.version < "2.17.1") | "\(.name) \(.version)")' {} \;
lab2:1 sha256:bee2f4c8c5065bfcc3ff623d969856b73997353272c8f0e9d55e3b5bba222601 log4j-core 2.14.1
lab2:2 sha256:f4a7dca7597e92089861f8d46b0d0310c92003a1db5bf91c3d67f38969e594a3 log4j-core 2.15.0
lab4:1 sha256:0e2988c10f592adb4a8d85bc9433b8ef38ce1918e3895115c71bc3ef3b3c0890 log4j-core 2.14.1
lab4:2 sha256:c9a0c9df88af4b5582915078654d327ad38186d033fdf3e7519214ae98257456 log4j-core 2.15.0
```

## 4. (TO DO) pipe all sboms into grype for CVE matching
for this and more advanced SBOM exercises, you can check out the workshop I put together for DevOps World 2022: https://github.com/pvnovarese/2022-devopsworld (this workshop wasn't delivered due to Hurricane Ian).


## 999. Jenkins Setup

If you don't have access to a Jenkins instance, you can deploy your own jenkins in a container (this fairly self-contained and easily disposable). This command will run jenkins and bind to the host's docker sock (if you don't know what that means, don't worry about it, it's not important).

```
$ docker run -u root -d --name jenkins --rm -p 8080:8080 -p 50000:50000 -v /var/run/docker.sock:/var/run/docker.sock -v /tmp/jenkins-data:/var/jenkins_home jenkinsci/blueocean
```

Once Jenkins is up and running, we have just a few things to configure:

    Get the initial password ($ docker logs jenkins)
    log in on port 8080
    Unlock Jenkins using the password from the logs (`docker logs jenkins`)
    Select “Install Selected Plugins” and create an admin user

If you'd like to create a more semi-permanent jenkins instance, use the docker-compose.yml file in this repo.

## Bibliography, Reading List, Footnotes, &c

* Dealing with log4shell (detection, mitigation, workarounds): https://cloudsecurityalliance.org/blog/2021/12/14/dealing-with-log4shell-aka-cve-2021-44228-aka-the-log4j-version-2/ 
* Keeping up with log4shell (post mortem) https://cloudsecurityalliance.org/blog/2021/12/16/keeping-up-with-log4shell-aka-cve-2021-44228-aka-the-log4j-version-2/ 
* Mysterious tweet hinting at the exploit: https://twitter.com/sirifu4k1/status/1468951859381485573 
* Another mysterious tweet: https://twitter.com/CattusGlavo/status/1469010118163374089 
* “THE” pull request: https://github.com/apache/logging-log4j2/pull/608 
* Cloudflare digs for evidence of pre-disclosure exploits in the wild: https://twitter.com/eastdakota/status/1469800951351427073 
* Draft of upcoming site content for SBOM.me: https://github.com/joshbressers/sbom-examples/blob/readme-update/site/index.md
* Reflections on Trusting Trust: https://www.cs.cmu.edu/~rdriley/487/papers/Thompson_1984_ReflectionsonTrustingTrust.pdf 
* Generate sboms with syft and jenkins: https://www.youtube.com/watch?v=nMLveJ_TxAs
* Solar Winds post mortem: https://www.lawfareblog.com/solarwinds-and-holiday-bear-campaign-case-study-classroom
* SPDX becomes sbom standard: https://www.linuxfoundation.org/press-release/spdx-becomes-internationally-recognized-standard-for-software-bill-of-materials
* Profound Podcast - Episode 10 (John Willis and Josh Corman): https://www.buzzsprout.com/1758599/8761108-profound-dr-deming-episode-10-josh-corman-captain-america 
* Creating a trusted container supply chain: https://thenewstack.io/creating-a-trusted-container-supply-chain/ 
* Accuracy and Precision: https://wps.prenhall.com/wps/media/objects/3310/3390101/blb0105.html 

### Footnotes

* Slide 2: https://twitter.com/codinghorror/status/786667942142435329
* Slide 6: https://www.mend.io/resources/blog/popular-cryptocurrency-exchange-dydx-has-had-its-npm-account-hacked/ 
* Slide 6: https://www.mend.io/resources/blog/cybercriminals-targeted-users-of-packages-with-a-total-of-1-5-billion-weekly-downloads-on-npm/ 
* Slide 7: https://joshdata.me/iceberger.html 
* Slide 16: https://twitter.com/dakami/status/896477575475642368
* Slides 14-15: https://www.blackhat.com/docs/us-16/materials/us-16-Munoz-A-Journey-From-JNDI-LDAP-Manipulation-To-RCE.pdf
* Slide 17: https://hypixel.net/threads/psa-there-is-a-fatal-remote-code-execution-exploit-in-minecraft-and-its-by-typing-in-chat.4703238/
* Slide 17: https://twitter.com/_r_netsec/status/1469120458083962882 
* Slide 17: https://twitter.com/eastdakota/status/1469800951351427073 
* Slides 18-19: https://twitter.com/CubicleApril/status/1469825942684160004
* Slides 18-19: https://www.linkedin.com/posts/novarese_log4j-log4shell-activity-6876206319238463488-8bEA 
* Slides 24-26: Maslow's Hierarchy of Supply Chain Needs: https://www.youtube.com/watch?v=rcP8QHFMwCw 
* Slide 27: https://en.wikipedia.org/wiki/USA-247 
* Slide 45: https://twitter.com/malwarejake/status/1432168973970313221 

Images used for SBOM generation timing benchmarks:
* registry.access.redhat.com/ubi8:latest 
* https://gitlab.com/pvn_test_images/devops-supply-chain 
* https://github.com/pvnovarese/devops-supply-chain-demo 

* Integration of cosign with syft: https://github.com/anchore/syft/issues/510
* Add support for Hints in syft: https://github.com/anchore/syft/issues/31 

