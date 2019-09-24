A starter iOS App that demonstrates the basic Couchbase Lite APIs.
The Couchbase Lite framework can be used in two modes
- Standalone mode as a local embedded database
- With a Remote Sync Gateway that allows you to replicate data across devices

### Prerequisites
- Xcode 11+
- Swift 5

### Deployment Target
- iOS8


### Standalone mode: 
This is the default mode (master branch). In this mode, Couchbase Lite is used exclusively as a local database and database transactions are not synched to remote database . 
For details, please refer to the blog post at https://blog.couchbase.com/couchbase-lite-embedded-in-ios-app-part1/ that discusses the code. 

```
git clone git@github.com:couchbaselabs/couchbase-lite-ios-standalone-sampleapp.git
cd couchbase-lite-ios-starterapp/
open CBLiteStarterApp.xcworkspace/
```

![alt text](https://blog.couchbase.com/wp-content/uploads/2017/04/cblitedemo.gif)

### Synchronization Mode:
To test out replication, please switch to `syncsupport` branch. In this mode, Couchbase Lite syncs (pulls and pushes changes continuously) with a remote Sync Gateway. 

```
git clone git@github.com:couchbaselabs/couchbase-lite-ios-standalone-sampleapp.git
git checkout syncsupport
```
For details, please refer to the blog post at http://blog.couchbase.com/data-sync-on-ios-couchbase-mobile/ that walks you through the code as well as the corresponding Sync Function to run on Sync Gateway.

![alt_text](https://blog.couchbase.com/wp-content/uploads/2017/04/demo_recording_short.gif)





