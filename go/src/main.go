package main
import (
	"github.com/takeoff-projects/j-wang/cf"
	"google.golang.org/api/pubsub/v1"
)

func main() {
	message := pubsub.PubsubMessage{
		Attributes: nil,
		Data: "bWVzc2FnZSBib2R5"}
	cf.ProcessOsrImport(nil, message)
}