package cf
import (
    "fmt" 
    "context"
    "google.golang.org/api/pubsub/v1"
)

func ProcessOsrImport(ctx context.Context, body pubsub.PubsubMessage) error {
    fmt.Println("hello world")
    fmt.Println(string(body.Data))
    return nil
}
