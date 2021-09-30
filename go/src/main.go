// This is just here so I can make sure there are no compile errors with the other file google libraries
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