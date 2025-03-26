package ihoje.gugu

import com.pulumi.{Context, Pulumi}
import com.pulumi.gcp.compute.{Instance, InstanceArgs}
import com.pulumi.gcp.compute.inputs.{
  InstanceBootDiskArgs, 
  InstanceBootDiskInitializeParamsArgs, 
  InstanceNetworkInterfaceArgs
}
import com.pulumi.gcp.storage.{Bucket, BucketArgs}
import scala.jdk.CollectionConverters.*
import ihoje.gugu.tobira.DeploymentConfig

/**
 * Main entry point for the Gugu infrastructure toolkit.
 * 
 * Named after Gugu from "To Your Eternity" - known for his extraordinary strength,
 * this module provides powerful GCP infrastructure management using Scala 3 and Pulumi.
 */
object Main:
  
  def main(args: Array[String]): Unit =
    Pulumi.run(ctx => {
      // Display welcome message
      val (name, version) = ("Gugu", "1.0.0")
      ctx.log.info(s"$name v$version - Powerful GCP Infrastructure Management")
      ctx.log.info("Named after the strongest character from 'To Your Eternity'")
      
      try
        // Create infrastructure based on project structure and templates
        deployInfrastructure(ctx)
      catch
        case e: Exception =>
          ctx.log.error(s"Failed to deploy infrastructure: ${e.getMessage}")
          throw e
    })
  
  /**
   * Deploy infrastructure resources defined in the project.
   */
  private def deployInfrastructure(ctx: Context): Unit =
    // Create an assets bucket
    val bucket = Bucket("gugu-assets-bucket",
      BucketArgs.builder()
        .location("US")
        .uniformBucketLevelAccess(true)
        .build()
    )
    
    // Deploy Tobira infrastructure (Container Registry + Cloud Run services)
    val (tobibaRepo, tobiraServiceMock, tobiraServiceMain) = DeploymentConfig.deploy(ctx)
    
    ctx.export("assetsBucketUrl", bucket.url())
    ctx.log.info("Infrastructure deployment completed successfully")
end Main