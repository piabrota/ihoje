package dev.gugu.compute

import com.pulumi.gcp.compute.{Instance, InstanceArgs}
import com.pulumi.gcp.compute.inputs.{
  InstanceBootDiskArgs, 
  InstanceBootDiskInitializeParamsArgs, 
  InstanceNetworkInterfaceArgs,
  InstanceNetworkInterfaceAccessConfigArgs
}
import scala.jdk.CollectionConverters.*

/**
 * Configuration for a Virtual Machine instance.
 * 
 * @param machineType The machine type to use (e.g., "e2-micro", "n2-standard-2")
 * @param zone The zone to deploy the VM in (e.g., "us-central1-a")
 * @param image The boot disk image to use (e.g., "debian-cloud/debian-11")
 * @param network The network to use (defaults to "default")
 * @param subnetwork Optional subnetwork to use
 * @param tags Optional network tags to apply to the instance
 * @param metadata Optional metadata key/value pairs
 * @param startupScript Optional startup script content
 */
case class VirtualMachineConfig(
  machineType: String,
  zone: String,
  image: String,
  network: String = "default",
  subnetwork: Option[String] = None,
  tags: List[String] = List.empty,
  metadata: Map[String, String] = Map.empty,
  startupScript: Option[String] = None
)

/**
 * Helper object for creating and managing GCP Compute Engine VMs.
 * 
 * Like Gugu from "To Your Eternity" who gained extraordinary strength through
 * training, this module provides robust and powerful compute resource management.
 */
object VirtualMachine:
  /**
   * Create a new GCP Compute Engine virtual machine.
   *
   * @param name The name of the virtual machine
   * @param config VM configuration
   * @return The created instance
   */
  def create(
    name: String,
    config: VirtualMachineConfig
  ): Instance =
    val metadataWithStartupScript = config.startupScript match
      case Some(script) => config.metadata + ("startup-script" -> script)
      case None => config.metadata
    
    val instanceArgs = InstanceArgs.builder()
      .machineType(config.machineType)
      .zone(config.zone)
      .bootDisk(InstanceBootDiskArgs.builder()
        .initializeParams(InstanceBootDiskInitializeParamsArgs.builder()
          .image(config.image)
          .build())
        .build())
      .networkInterfaces(InstanceNetworkInterfaceArgs.builder()
        .network(config.network)
        .apply(builder => 
          config.subnetwork.foreach(subnet => builder.subnetwork(subnet))
          builder
        )
        .accessConfigs(InstanceNetworkInterfaceAccessConfigArgs.builder().build())
        .build())
      .tags(config.tags.asJava)
      .metadatas(metadataWithStartupScript.asJava)
      .build()
    
    new Instance(name, instanceArgs)
  
  /**
   * Extensions for working with instances
   */
  extension (instance: Instance)
    /**
     * Get the public IP address of the VM.
     */
    def publicIp = 
      instance.networkInterfaces().applyValue(nics => 
        nics.get(0).accessConfigs().get(0).natIp())
    
    /**
     * Get the private IP address of the VM.
     */
    def privateIp = 
      instance.networkInterfaces().applyValue(nics => nics.get(0).networkIp())
    
    /**
     * Get the zone of the VM.
     */
    def zone = instance.zone()
end VirtualMachine