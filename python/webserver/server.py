from http.server import SimpleHTTPRequestHandler, HTTPServer
import logging

class HTTPHandler(SimpleHTTPRequestHandler):
    def _set_response(self): #respond with OK status code
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()

    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        #print uploaded file
        logging.info(post_data.decode('utf-8'))
        self._set_response()

def run(server_class=HTTPServer, handler_class=HTTPHandler, port=8080):
    logging.basicConfig(level=logging.INFO)
    server_address = ('', port) #listen on any interface
    httpd = server_class(server_address, handler_class)
    logging.info('httpd started\n')
    try:
        httpd.serve_forever() #start HTTP server
    except KeyboardInterrupt:
        pass
    httpd.server_close()
    logging.info('httpd ended\n')

if __name__ == '__main__':
    from sys import argv

    if len(argv) == 2:
        #optionally set a different port (default 8080)
        run(port=int(argv[1]))
    else:
        run()