package cf
import (
    "fmt"
    "time"
    "context"
    "encoding/json"
	"net/http"
    "google.golang.org/api/iterator"
    "google.golang.org/api/pubsub/v1"
    b64 "encoding/base64"
    firebase "firebase.google.com/go"
  )

type Message struct {
	Timestamp string
	Message   string
}

func ProcessOsrImport(ctx context.Context, body pubsub.PubsubMessage) error {
    conf := &firebase.Config{ProjectID: "roi-takeoff-user44"}
    app, appErr := firebase.NewApp(ctx, conf)
    // TODO: Actually error
    if appErr != nil {
        fmt.Println("App Error")
        fmt.Println(appErr)
    }

    client, clientErr := app.Firestore(ctx)
    if clientErr != nil {
        fmt.Println("Client Error")
        fmt.Println(clientErr)
    }
    decodedBody, _ := b64.StdEncoding.DecodeString(body.Data)
    // TODO: Figure out why this doesn't like a struct
    _, _, collectionErr := client.Collection("import_messages").Add(ctx, map[string]string{
        "Timestamp": time.Now().Format(time.RFC822Z),
        "Message": string(decodedBody),
    })
    if collectionErr != nil {
        fmt.Print(collectionErr)
    }
    defer client.Close()

    return nil
}

func GetOsrImportMessages(w http.ResponseWriter, r *http.Request) {
    ctx := context.Background()
    conf := &firebase.Config{ProjectID: "roi-takeoff-user44"}
	var messages []map[string]string

    app, appErr := firebase.NewApp(ctx, conf)
    if appErr != nil {
        fmt.Println("App Error")
        fmt.Println(appErr)
    }

    client, clientErr := app.Firestore(ctx)
    if clientErr != nil {
        fmt.Println("Client Error")
        fmt.Println(clientErr)
    }

    iter := client.Collection("import_messages").Documents(ctx)
    defer iter.Stop()
    for {
        doc, err := iter.Next()
        if err == iterator.Done {
            break
        }
        var m map[string]string
        doc.DataTo(&m)
        messages = append(messages, m)
    }

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(messages)
    defer client.Close()
}
