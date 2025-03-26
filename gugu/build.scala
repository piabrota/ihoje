//> using scala "3.3.1"
//> using repository "https://repo1.maven.org/maven2"

// Pulumi dependencies
//> using lib "com.pulumi:pulumi:3.91.1"
//> using lib "com.pulumi:gcp:7.9.0"

// Scala libraries
//> using lib "org.typelevel::cats-core:2.10.0"
//> using lib "org.typelevel::cats-effect:3.5.2"

// Testing
//> using lib "org.scalatest::scalatest:3.2.17" 

// Logging
//> using lib "org.slf4j:slf4j-api:2.0.9"
//> using lib "ch.qos.logback:logback-classic:1.4.14"

// ScalaFix
//> using lib "org.scalameta::scalafix-core:0.11.1"
//> using lib "org.scalameta::scalafix-rules:0.11.1"

// Resource directories
//> using resourceDir "src/main/resources"
//> using test.resourceDir "src/test/resources"

// Compiler options
//> using option "-deprecation"
//> using option "-feature"
//> using option "-unchecked"
//> using option "-Xfatal-warnings"

// Test framework
//> using testFramework "org.scalatest.tools.Framework"

// ScalaFix configuration
// Commented out to fix CI issues
//# using file .scalafix.conf