package ihoje.gugu.artifactregistry

import com.pulumi.gcp.artifactregistry.{Repository => GcpRepository, RepositoryArgs}
import com.pulumi.core.Output
import scala.jdk.CollectionConverters.*

/**
 * Configuration for an Artifact Registry repository.
 * 
 * @param description Description of the repository
 * @param format Format of the repository (e.g., "DOCKER", "MAVEN", "NPM")
 * @param location Location of the repository (e.g., "us-central1")
 * @param labels Optional labels to apply
 */
case class RepositoryConfig(
  description: String,
  format: String = "DOCKER",
  location: String = "us-central1",
  labels: Map[String, String] = Map.empty
)

/**
 * Helper object for creating and managing GCP Artifact Registry repositories.
 */
object Repository:
  /**
   * Create a new GCP Artifact Registry repository.
   *
   * @param name The name of the repository
   * @param config Repository configuration
   * @return The created repository
   */
  def create(
    name: String,
    config: RepositoryConfig
  ): GcpRepository =
    val repositoryArgs = RepositoryArgs.builder()
      .description(config.description)
      .format(config.format)
      .location(config.location)
      .labels(config.labels.asJava)
      .build()

    new GcpRepository(name, repositoryArgs)

  /**
   * Extensions for working with repositories
   */
  extension (repository: GcpRepository)
    /**
     * Get the repository ID.
     */
    def repositoryId = repository.id()
    
    /**
     * Get the registry hostname.
     */
    def registryHost = Output.format("%s-docker.pkg.dev", repository.location())
    
    /**
     * Get the full repository path for a project.
     */
    def fullRepositoryPath(projectId: Output[String]) = 
      Output.format("%s-docker.pkg.dev/%s/%s", 
        repository.location(), 
        projectId, 
        repository.name())
end Repository