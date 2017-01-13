// {{ method.name }} (Client Streaming)
public class {{ .|session:protoFile,service,method }} : {{ .|service:protoFile,service }}Session {
  private var handler : gRPC.Handler
  private var provider : {{ .|provider:protoFile,service }}

  /// Create a session.
  fileprivate init(handler:gRPC.Handler, provider: {{ .|provider:protoFile,service }}) {
    self.handler = handler
    self.provider = provider
  }

  /// Receive a message. Blocks until a message is received or the client closes the connection.
  public func Receive() throws -> {{ method|input }} {
    let done = NSCondition()
    var requestMessage : {{ method|input }}?
    try self.handler.receiveMessage() {(requestData) in
      if let requestData = requestData {
        requestMessage = try? {{ method|input }}(protobuf:requestData)
      }
      done.lock()
      done.signal()
      done.unlock()
    }
    done.lock()
    done.wait()
    done.unlock()
    if requestMessage == nil {
      throw {{ .|servererror:protoFile,service }}.endOfStream
    }
    return requestMessage!
  }

  /// Send a response and close the connection.
  public func SendAndClose(_ response: {{ method|output }}) throws {
    try self.handler.sendResponse(message:response.serializeProtobuf(),
                                  statusCode:self.statusCode,
                                  statusMessage:self.statusMessage,
                                  trailingMetadata:self.trailingMetadata)
  }

  /// Run the session. Internal.
  fileprivate func run(queue:DispatchQueue) throws {
    try self.handler.sendMetadata(initialMetadata:initialMetadata) {
      queue.async {
        do {
          try self.provider.{{ method.name|lowercase }}(session:self)
        } catch (let error) {
          print("error \(error)")
        }
      }
    }
  }
}