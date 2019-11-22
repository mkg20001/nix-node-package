- some way to let npm resolve modules using the native module module from nixstore
  - so when loading a piece of js code the native modulemodule would be given a tree of dependencies and then resolve the dependencies from there
    {
      hello: {
        resolve: (hello)
        namespace: {
          hello2: {
            resolve: (hello2)
          }
        }
      }
    }
