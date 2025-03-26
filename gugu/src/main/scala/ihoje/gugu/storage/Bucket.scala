package ihoje.gugu.storage

import com.pulumi.gcp.storage.{Bucket => GcpBucket, BucketArgs}
import scala.jdk.CollectionConverters.*

/**
 * Configuration for a Storage Bucket.
 * 
 * @param location The bucket location (e.g., "US", "EU", "us-central1")
 * @param versioning Whether to enable versioning 
 * @param publicAccess Whether the bucket is publicly accessible
 * @param uniformAccess Whether to enable uniform bucket-level access
 * @param lifecycle Optional lifecycle rules
 * @param labels Optional labels to apply
 */
case class BucketConfig(
  location: String,
  versioning: Boolean = false,
  publicAccess: Boolean = false,
  uniformAccess: Boolean = true,
  lifecycle: List[BucketLifecycleRule] = List.empty,
  labels: Map[String, String] = Map.empty
)

/**
 * Lifecycle rule for a bucket.
 * 
 * @param action The action to take (e.g., "Delete", "SetStorageClass")
 * @param storageClass The storage class to set if applicable
 * @param ageDays Age in days for the condition
 * @param createdBefore Date in RFC 3339 format for the condition
 * @param withState State condition ("ANY", "LIVE", "ARCHIVED")
 */
case class BucketLifecycleRule(
  action: String,
  storageClass: Option[String] = None,
  ageDays: Option[Int] = None, 
  createdBefore: Option[String] = None,
  withState: Option[String] = None
)

/**
 * Helper object for creating and managing GCP Storage Buckets.
 * 
 * Like Gugu from "To Your Eternity" who uses his special mask to focus his 
 * abilities, this module provides robust storage management with protection 
 * and resilience.
 */
object Bucket:
  /**
   * Create a new GCP Storage bucket.
   *
   * @param name The name of the bucket
   * @param config Bucket configuration
   * @return The created bucket
   */
  def create(
    name: String,
    config: BucketConfig
  ): GcpBucket =
    // Convert lifecycle rules to Pulumi format
    val lifecycleRules = config.lifecycle.map(rule => 
      com.pulumi.gcp.storage.inputs.BucketLifecycleRuleArgs.builder()
        .action(com.pulumi.gcp.storage.inputs.BucketLifecycleRuleActionArgs.builder()
          .type(rule.action)
          .apply(builder => 
            rule.storageClass.foreach(sc => builder.storageClass(sc))
            builder
          )
          .build())
        .condition(com.pulumi.gcp.storage.inputs.BucketLifecycleRuleConditionArgs.builder()
          .apply(builder => {
            rule.ageDays.foreach(age => builder.age(age))
            rule.createdBefore.foreach(date => builder.createdBefore(date))
            rule.withState.foreach(state => builder.withState(state))
            builder
          })
          .build())
        .build()
    ).asJava
    
    val bucketArgs = BucketArgs.builder()
      .location(config.location)
      .uniformBucketLevelAccess(config.uniformAccess)
      .versioning(com.pulumi.gcp.storage.inputs.BucketVersioningArgs.builder()
        .enabled(config.versioning)
        .build())
      .labels(config.labels.asJava)
      .apply(builder => 
        if !config.lifecycle.isEmpty then
          builder.lifecycleRules(lifecycleRules)
        builder
      )
      .build()
    
    new GcpBucket(name, bucketArgs)
  
  /**
   * Extensions for working with buckets
   */
  extension (bucket: GcpBucket)
    /**
     * Get the URL of the bucket.
     */
    def url = bucket.url()
    
    /**
     * Get the name of the bucket.
     */
    def name = bucket.name()
    
    /**
     * Get the self-link of the bucket.
     */
    def selfLink = bucket.selfLink()
end Bucket