package cf
import (
    "fmt"
    "time"
    "context"
    "google.golang.org/api/pubsub/v1"

    firebase "firebase.google.com/go"
  )

func ProcessOsrImport(ctx context.Context, body pubsub.PubsubMessage) error {
    conf := &firebase.Config{ProjectID: "roi-takeoff-user44"}
    app, appErr := firebase.NewApp(ctx, conf)
    if appErr != nil {
        fmt.Print(appErr)
    }

    client, firestoreErr := app.Firestore(ctx)
    if firestoreErr != nil {
        fmt.Print(firestoreErr)
    }

    _, _, collectionErr := client.Collection("import_messages").Add(ctx, map[string]string{
        "timestamp": time.Now().Format(time.RFC822Z),
        "message": body.Data,
    })
    if collectionErr != nil {
        fmt.Print(collectionErr)
    }
    defer client.Close()

    return nil
}
