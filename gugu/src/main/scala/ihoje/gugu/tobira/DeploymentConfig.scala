package ihoje.gugu.tobira

import com.pulumi.gcp.cloudrun.Service
import com.pulumi.core.Output
import com.pulumi.gcp.cloudrun.ServiceArgs
import ihoje.gugu.cloudrun.{CloudRunConfig, Service => CloudRunService}
import ihoje.gugu.artifactregistry.{RepositoryConfig, Repository => ArtifactRepository}
import com.pulumi.gcp.cloudrun.inputs.ServiceTemplateArgs
import com.pulumi.Pulumi
import com.pulumi.Context

/**
 * Configuration for Tobira deployments.
 */
object DeploymentConfig:
  /**
   * Deploy the Tobira infrastructure.
   *
   * @param ctx The Pulumi context
   * @return A tuple of (repository, mock service, main service)
   */
  def deploy(ctx: Context): (
    com.pulumi.gcp.artifactregistry.Repository, 
    com.pulumi.gcp.cloudrun.Service, 
    com.pulumi.gcp.cloudrun.Service
  ) =
    ctx.log.info("Deploying Tobira infrastructure...")

    // Get current GCP project ID
    val gcpConfig = com.pulumi.gcp.Config()
    val projectId = gcpConfig.requireProject()
    
    // Create Artifact Registry repository for Tobira container images
    val repository = ArtifactRepository.create("tobira-containers",
      RepositoryConfig(
        description = "Container registry for Tobira frontend images",
        format = "DOCKER",
        location = "us-central1",
        labels = Map(
          "app" -> "tobira",
          "managed-by" -> "pulumi"
        )
      )
    )
    
    val repositoryPath = repository.fullRepositoryPath(projectId)
    
    // Deploy the mock Tobira service
    val mockService = CloudRunService.create("tobira-mock",
      CloudRunConfig(
        image = Output.format("%s/mock:latest", repositoryPath).apply(_.toString),
        port = 8080,
        location = "us-central1",
        allowUnauthenticated = true,
        cpuLimit = "1000m",
        memoryLimit = "512Mi",
        minInstances = 0,
        maxInstances = 2,
        environmentVariables = Map(
          "IHOJE_ENVIRONMENT" -> "production"
        )
      )
    )
    
    // Make mock service publicly accessible
    val mockPublicAccess = CloudRunService.makePublic(mockService)
    
    // Deploy the main Tobira service
    val mainService = CloudRunService.create("shinri-no-tobira",
      CloudRunConfig(
        image = Output.format("%s/shinri-no-tobira:latest", repositoryPath).apply(_.toString),
        port = 8080,
        location = "us-central1",
        allowUnauthenticated = true,
        cpuLimit = "1000m",
        memoryLimit = "1Gi",
        minInstances = 0,
        maxInstances = 3,
        environmentVariables = Map(
          "IHOJE_ENVIRONMENT" -> "production",
          "IHOJE_API_URL" -> "https://api.ihoje.app"
        )
      )
    )
    
    // Make main service publicly accessible
    val mainPublicAccess = CloudRunService.makePublic(mainService)
    
    // Export URLs
    ctx.export("mockServiceUrl", mockService.url)
    ctx.export("mainServiceUrl", mainService.url)
    ctx.export("containerRegistry", repositoryPath)
    
    (repository, mockService, mainService)
end DeploymentConfig