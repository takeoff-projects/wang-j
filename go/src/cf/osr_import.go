package cf
import (
    "fmt"
    "time"
    "context"
    "google.golang.org/api/pubsub/v1"
	"net/http"
    "encoding/json"
    "io"
    "html"
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

func GetOsrImportMessages(w http.ResponseWriter, r *http.Request) {
	var d struct {
		Message string `json:"message"`
	}

	if err := json.NewDecoder(r.Body).Decode(&d); err != nil {
		switch err {
		case io.EOF:
			fmt.Fprint(w, "Hello World!")
			return
		default:
			http.Error(w, http.StatusText(http.StatusBadRequest), http.StatusBadRequest)
			return
		}
	}

	if d.Message == "" {
		fmt.Fprint(w, "Hello World!")
		return
	}
	fmt.Fprint(w, html.EscapeString(d.Message))
}
