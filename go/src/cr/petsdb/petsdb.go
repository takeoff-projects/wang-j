package petsdb

import (
	
	"context"
	"fmt"
	"log"
	"os"
	"google.golang.org/api/iterator"
	firebase "firebase.google.com/go"
)

var projectID string

type Message struct {
	Timestamp string `firebase:"timestamp"`
	Message   string `firebase:"message"`
}

// GetPets Returns all pets from datastore ordered by likes in Desc Order
func GetPets() ([]Message, error) {

	projectID = os.Getenv("GOOGLE_CLOUD_PROJECT")
	if projectID == "" {
		log.Fatal(`You need to set the environment variable "GOOGLE_CLOUD_PROJECT"`)
	}
	conf := &firebase.Config{ProjectID: projectID}
	ctx := context.Background()
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
	var messages []Message

  iter := client.Collection("import_messages").Documents(ctx)
  defer iter.Stop()
  for {
      doc, err := iter.Next()
      if err == iterator.Done {
          break
      }
      var m map[string]string
      doc.DataTo(&m)
      messages = append(messages, Message{Timestamp: m["timestamp"], Message: m["message"]})
  }
	client.Close()
	return messages, nil
}
