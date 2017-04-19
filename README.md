A very simple example of an iOS App that demonstrates the basics of integrating with Couchbase Lite (v1.4). The Couchbase Lite framework is used in standalone mode without a remote Sync Server.

### Prerequisites
- Xcode 8.3+
- Swift 3

### Deployment Target
- iOS8


### Standalone mode: 
This is the default mode (master branch). In this mode, Couchbase Lite is used exclusively as a local database and database transactions are not synched to remote database . 
For details, please refer to the blog post at https://blog.couchbase.com/couchbase-lite-embedded-in-ios-app-part1/  for details on running app in Standalone mode . 
![alt text](https://blog.couchbase.com/wp-content/uploads/2017/04/cblitedemo.gif)

### Synchronization Mode:
To test out replication, please switch to `syncsupport` branch. In this mode, Couchbase Lite syncs (pulls and pushes changes continuously) with a remote Sync Gateway. Details coming soon. 

```
git clone git@github.com:couchbaselabs/couchbase-lite-ios-standalone-sampleapp.git
git checkout syncsupport
```




