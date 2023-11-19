import base64, strformat, httpclient, net, json, uri, strutils

type 
  BasicAuth* = tuple[login: string, password: string] ## Basic auth type
  Header* = tuple[key: string, value: string] ## Type for HTTP header
  QueryParam* = tuple[key: string, value: string] ## Type for URL query params

  Method* = enum
    ## Supported HTTP methods
    GET, PUT, POST, PATCH, DELETE, HEAD, OPTIONS

  Response* = object
    ## Type for HTTP response
    status*: int
    body*: string


proc json*(response: Response): JsonNode = 
  ## Parses response body to json 
  return parseJson(response.body)


proc to*[T](response: Response, t: typedesc[T]): T =
  ## Parses response body to json and then casts it to passed type
  return to(response.json(), t)


proc ok*(response: Response): bool = 
  ## Is HTTP status in OK range (> 0 and < 400)? 
  return response.status > 0 and response.status < 400 


proc basicAuthHeader(auth: BasicAuth): string = 
  let strToEncode = auth.login & ":" & auth.password;
  return fmt"Basic {encode(strToEncode)}"


proc request*(url: string, httpMethod: Method = Method.GET, headers: openArray[Header] = @[], queryParams: openArray[QueryParam] = @[], body: string = "", auth: BasicAuth = ("", ""), ignoreSsl = false): Response = 
  ## Genreal proc to make HTTP request with every HTTP method

  # Prepare client

  var client: HttpClient = if ignoreSsl:
      newHttpClient(sslContext=newContext(verifyMode=CVerifyNone))
    else:
      newHttpClient()

  # Prepare headers

  var innerHeaders: seq[tuple[key: string, val: string]] = @[]

  for header in headers:
    innerHeaders.add((header.key, header.value))

  if auth.login != "" and auth.password != "":
    innerHeaders.add({"Authorization": auth.basicAuthHeader()})

  if innerHeaders.len() > 0:
    client.headers = newHttpHeaders(innerHeaders)

  # Prepare url

  var innerUrl = url

  # Prepare query params
  if queryParams.len() > 0:
    innerUrl &= fmt"?{encodeQuery(queryParams, usePlus=false)}"

  # Prepare HTTP method

  var innerMethod: HttpMethod = case httpMethod:
    of Method.GET: HttpGet
    of Method.PUT: HttpPut
    of Method.POST: HttpPost
    of Method.PATCH: HttpPatch
    of Method.DELETE: HttpDelete
    of Method.HEAD: HttpHead
    of Method.OPTIONS: HttpOptions

  # Make request

  let response = client.request(innerUrl, httpMethod = innerMethod, body = body)
  client.close()

  return Response(status: parseInt(response.status.strip()), body: response.body)


# Deidcated procs for individual methods

proc get*(url: string, headers: openArray[Header] = @[], queryParams: openArray[QueryParam] = @[], auth: BasicAuth = ("", ""), ignoreSsl = false): Response = 
  return request(
    url = url,
    httpMethod = Method.GET, 
    headers = headers,
    queryParams = queryParams,
    auth = auth,
    ignoreSsl = ignoreSsl
  )

proc put*(url: string, headers: openArray[Header] = @[], queryParams: openArray[QueryParam] = @[], body: string = "", auth: BasicAuth = ("", ""), ignoreSsl = false): Response = 
  return request(
    url = url,
    httpMethod = Method.PUT, 
    headers = headers,
    queryParams = queryParams,
    body = body,
    auth = auth,
    ignoreSsl = ignoreSsl
  )

proc post*(url: string, headers: openArray[Header] = @[], queryParams: openArray[QueryParam] = @[], body: string = "", auth: BasicAuth = ("", ""), ignoreSsl = false): Response = 
  return request(
    url = url,
    httpMethod = Method.POST, 
    headers = headers,
    queryParams = queryParams,
    body = body,
    auth = auth,
    ignoreSsl = ignoreSsl
  )

proc patch*(url: string, headers: openArray[Header] = @[], queryParams: openArray[QueryParam] = @[], body: string = "", auth: BasicAuth = ("", ""), ignoreSsl = false): Response = 
  return request(
    url = url,
    httpMethod = Method.PATCH, 
    headers = headers,
    queryParams = queryParams,
    body = body,
    auth = auth,
    ignoreSsl = ignoreSsl
  )


proc delete*(url: string, headers: openArray[Header] = @[], queryParams: openArray[QueryParam] = @[], body: string = "", auth: BasicAuth = ("", ""), ignoreSsl = false): Response = 
  return request(
    url = url,
    httpMethod = Method.DELETE, 
    headers = headers,
    queryParams = queryParams,
    body = body,
    auth = auth,
    ignoreSsl = ignoreSsl
  )

proc head*(url: string, headers: openArray[Header] = @[], queryParams: openArray[QueryParam] = @[], auth: BasicAuth = ("", ""), ignoreSsl = false): Response = 
  return request(
    url = url,
    httpMethod = Method.HEAD, 
    headers = headers,
    queryParams = queryParams,
    auth = auth,
    ignoreSsl = ignoreSsl
  )

proc options*(url: string, headers: openArray[Header] = @[], queryParams: openArray[QueryParam] = @[], auth: BasicAuth = ("", ""), ignoreSsl = false): Response = 
  return request(
    url = url,
    httpMethod = Method.OPTIONS, 
    headers = headers,
    queryParams = queryParams,
    auth = auth,
    ignoreSsl = ignoreSsl
  )
