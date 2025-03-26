package ihoje.gugu.cloudrun

import com.pulumi.gcp.cloudrun.{Service => CloudRunService, ServiceArgs}
import com.pulumi.gcp.cloudrun.inputs.{
  ServiceTemplateArgs,
  ServiceTemplateContainerArgs,
  ServiceTemplateContainerPortArgs,
  ServiceTemplateContainerEnvArgs,
  ServiceTrafficArgs
}
import com.pulumi.core.Output
import scala.jdk.CollectionConverters.*

/**
 * Configuration for a Cloud Run service.
 * 
 * @param image The container image to deploy (e.g., "gcr.io/project-id/image:tag")
 * @param port The port the container listens on
 * @param location The region to deploy the service in (e.g., "us-central1")
 * @param allowUnauthenticated Whether to allow unauthenticated access
 * @param cpuLimit CPU limit (e.g., "1000m" for 1 vCPU)
 * @param memoryLimit Memory limit (e.g., "512Mi")
 * @param minInstances Minimum number of instances (0 for scale to zero)
 * @param maxInstances Maximum number of instances 
 * @param concurrency Maximum requests per instance
 * @param timeout Request timeout in seconds
 * @param environmentVariables Environment variables to set
 * @param vpcConnector Optional Serverless VPC Access connector name
 * @param vpcEgress VPC egress setting ("private-ranges-only" or "all-traffic")
 * @param securitySettings Security settings configuration
 */
case class CloudRunConfig(
  image: String,
  port: Int = 8080,
  location: String = "us-central1",
  allowUnauthenticated: Boolean = false,
  cpuLimit: String = "1000m",
  memoryLimit: String = "512Mi",
  minInstances: Int = 0,
  maxInstances: Int = 100,
  concurrency: Int = 80,
  timeout: Int = 300,
  environmentVariables: Map[String, String] = Map.empty,
  vpcConnector: Option[String] = None,
  vpcEgress: Option[String] = None,
  securitySettings: SecuritySettings = SecuritySettings()
)

/**
 * Security settings for Cloud Run services.
 *
 * @param containerAnalysisEnabled Enable Container Analysis API for vulnerability scanning
 * @param cloudSqlInstances List of Cloud SQL instances to connect to
 * @param secretEnvironmentVariables Secret environment variables from Secret Manager
 * @param serviceAccountEmail Custom service account email
 */
case class SecuritySettings(
  containerAnalysisEnabled: Boolean = true,
  cloudSqlInstances: List[String] = List.empty,
  secretEnvironmentVariables: Map[String, String] = Map.empty,
  serviceAccountEmail: Option[String] = None
)

/**
 * Helper object for creating and managing GCP Cloud Run services.
 */
object Service:
  /**
   * Create a new GCP Cloud Run service.
   *
   * @param name The name of the service
   * @param config Service configuration
   * @return The created service
   */
  def create(
    name: String,
    config: CloudRunConfig
  ): CloudRunService =
    // Build environment variables
    val envVars = config.environmentVariables.map { case (key, value) =>
      ServiceTemplateContainerEnvArgs.builder()
        .name(key)
        .value(value)
        .build()
    }.toList.asJava

    // Create the service
    val serviceArgs = ServiceArgs.builder()
      .location(config.location)
      .template(ServiceTemplateArgs.builder()
        .containers(ServiceTemplateContainerArgs.builder()
          .image(config.image)
          .ports(ServiceTemplateContainerPortArgs.builder()
            .containerPort(config.port)
            .build())
          .resources(com.pulumi.gcp.cloudrun.inputs.ServiceTemplateContainerResourcesArgs.builder()
            .limits(Map(
              "cpu" -> config.cpuLimit,
              "memory" -> config.memoryLimit
            ).asJava)
            .build())
          .envs(envVars)
          .build())
        .containerConcurrency(config.concurrency)
        .timeoutSeconds(config.timeout)
        .build())
      .autogenerateRevisionName(true)
      .traffics(ServiceTrafficArgs.builder()
        .percent(100)
        .latestRevision(true)
        .build())
      .build()

    new CloudRunService(name, serviceArgs)

  /**
   * Make a Cloud Run service publicly accessible.
   *
   * @param service The Cloud Run service
   * @return The IAM policy that makes the service publicly accessible
   */
  def makePublic(service: CloudRunService): com.pulumi.gcp.cloudrun.IamMember =
    val noAuthIamMember = com.pulumi.gcp.cloudrun.IamMemberArgs.builder()
      .location(service.location())
      .service(service.name())
      .role("roles/run.invoker")
      .member("allUsers")
      .build()

    new com.pulumi.gcp.cloudrun.IamMember(s"${service.name().get()}-public-access", noAuthIamMember)

  /**
   * Extensions for working with Cloud Run services
   */
  extension (service: CloudRunService)
    /**
     * Get the URL of the service.
     */
    def url = service.statuses().applyValue(statuses => 
      if statuses.isEmpty() then "" else statuses.get(0).url())
  
    /**
     * Get the latest revision name.
     */
    def latestRevision = service.statuses().applyValue(statuses => 
      if statuses.isEmpty() then "" else statuses.get(0).latestCreatedRevisionName())
end Service