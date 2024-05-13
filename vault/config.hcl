storage "consul" {
    address = "127.0.0.1:8500"
    path    = "vault/"
}

address = "http://127.0.0.1:8200"

listener "tcp" {
    address     = "0.0.0.0:8200"
    tls_disable = 1
}

ui = true
