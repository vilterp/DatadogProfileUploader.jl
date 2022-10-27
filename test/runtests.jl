using DatadogProfileUploader

function myfunc()
  A = rand(2000, 200, 400)
  sort(A, dims=3)
end

nc_config = DatadogProfileUploader.DDConfig(
  "localhost",
  9000,
  "http",
  "petesrelmacbook.taila7a54.ts.net",
  ENV["DD_API_KEY"],
)

direct_config = DatadogProfileUploader.DDConfig(
  hostname="petesrelmacbook.taila7a54.ts.net",
  api_key=ENV["DD_API_KEY"],
)

DatadogProfileUploader.upload_file_on_disk(direct_config, "./cpu.pprof")
