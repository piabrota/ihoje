//package br.ihoje.cache
//
//import com.github.benmanes.caffeine.cache.RemovalCause
//import com.github.benmanes.caffeine.cache.stats.{ CacheStats, StatsCounter }
//
//import java.net.URL
//import scala.concurrent.Future
//import scala.concurrent.duration.*
//import com.github.blemale.scaffeine.{ Cache, Scaffeine }
////import kamon.instrumentation.caffeine.KamonStatsCounter
//
///**
//  * An in-memory cache implementation backed by Caffeine
//  * It uses <code> Window TinyLfu </code>
//  *
// * See: https://github.com/ben-manes/caffeine/wiki/Efficiency
//  */
//class InMemoryCrawlerCache(cache: Cache[URL, Set[URL]]) extends WebCrawlerCache:
//  override def get(key: URL): Future[Option[Set[URL]]] =
//    Future.successful(cache.getIfPresent(key))
//
//  override def set(key: URL, value: Set[URL]): Future[Unit] =
//    Future.successful(cache.put(key, value))
//
//class MyCounter() extends StatsCounter:
//
//  override def recordHits(count: Int): Unit = print("a")
//
//  override def recordMisses(count: Int): Unit = print("b")
//
//  override def recordLoadSuccess(loadTime: Long): Unit = print("c")
//
//  override def recordLoadFailure(loadTime: Long): Unit = print("d")
//
//  override def recordEviction(weight: Int, cause: RemovalCause): Unit = print("e")
//
//  override def snapshot(): CacheStats = ???
//object InMemoryCrawlerCache:
//  def apply(maxSize: Int, cacheExpiry: FiniteDuration): InMemoryCrawlerCache =
//    val cache: Cache[URL, Set[URL]] =
//      Scaffeine()
//        .expireAfterWrite(cacheExpiry)
//        .maximumSize(maxSize)
//        .recordStats(() => new MyCounter())
//        .build[URL, Set[URL]]()
//
//    new InMemoryCrawlerCache(cache)
