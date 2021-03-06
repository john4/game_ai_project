import java.util.LinkedList;

class MessageQueue {
  LinkedList<Message> messages;
  int length = 0;

  public MessageQueue() {
    messages = new LinkedList<Message>();
  }

  public void add(Message message) {
    if(length > 10) {
      messages.remove();
    } else {
      length++;
    }
    messages.add(message);
  }

  public void clean(double currentTime) {
    for(Message message: messages) {
      if(message.expiration < currentTime) {
        messages.remove();
        length--;
      }
      return;
    }
  }

  public int size() {
    return length;
  }
}

class Message {
  String message;
  double expiration; // messages should be removed after the expiration time

  Message(String message, double expiration) {
    this.message = message;
    this.expiration = expiration;
  }

  Message(String message) {
    this(message, 10);
  }
}
