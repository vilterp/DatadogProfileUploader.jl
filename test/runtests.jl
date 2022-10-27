using DatadogProfileUploader

function myfunc()
  A = rand(2000, 200, 400)
  sort(A, dims=3)
end

tags = Dict(
  "service" => "julia-sorter-3",
  "version" => "abc123",
  "env" => "dev",
)

hostname = "petesrelmacbook.taila7a54.ts.net"

nc_config = DatadogProfileUploader.DDConfig(
  host="localhost",
  port=9000,
  protocol="http",
  hostname=hostname,
  api_key=ENV["DD_API_KEY"],
  tags=tags,
)

direct_config = DatadogProfileUploader.DDConfig(
  hostname=hostname,
  api_key=ENV["DD_API_KEY"],
  tags=tags,
)

agent_config = DatadogProfileUploader.DDConfig(
  hostname=hostname,
  api_key=ENV["DD_API_KEY"],
  tags=tags,
)

DatadogProfileUploader.upload_file_on_disk(agent_config, "./cpu.pprof")
