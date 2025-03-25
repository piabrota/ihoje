package dev.gugu

import com.pulumi.{Context, Pulumi}
import com.pulumi.gcp.compute.{Instance, InstanceArgs}
import com.pulumi.gcp.compute.inputs.{
  InstanceBootDiskArgs, 
  InstanceBootDiskInitializeParamsArgs, 
  InstanceNetworkInterfaceArgs
}
import com.pulumi.gcp.storage.{Bucket, BucketArgs}
import scala.jdk.CollectionConverters.*

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
    // Example: Create a GCP storage bucket
    val bucket = Bucket("gugu-assets-bucket",
      BucketArgs.builder()
        .location("US")
        .uniformBucketLevelAccess(true)
        .build()
    )
    
    // Example: Create a GCP compute instance
    val instance = Instance("gugu-vm",
      InstanceArgs.builder()
        .machineType("e2-micro")
        .zone("us-central1-a")
        .bootDisk(InstanceBootDiskArgs.builder()
          .initializeParams(InstanceBootDiskInitializeParamsArgs.builder()
            .image("debian-cloud/debian-11")
            .build())
          .build())
        .networkInterfaces(InstanceNetworkInterfaceArgs.builder()
          .network("default")
          .accessConfigs(
            com.pulumi.gcp.compute.inputs.InstanceNetworkInterfaceAccessConfigArgs.builder().build()
          )
          .build())
        .tags(List("http-server", "https-server").asJava)
        .build()
    )
    
    // Export the instance IP and bucket URL
    ctx.export("instanceIp", instance.networkInterfaces().applyValue(nics => 
      nics.get(0).accessConfigs().get(0).natIp()))
    ctx.export("bucketUrl", bucket.url())
    
    ctx.log.info("Infrastructure deployment completed successfully")
end Main