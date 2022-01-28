using DatadogProfileUploader

function myfunc()
  A = rand(200, 200, 400)
  maximum(A)
end

config = DatadogProfileUploader.DDConfig("localhost", 8126, ENV["DD_API_KEY"])

DatadogProfileUploader.profile_and_upload(config, myfunc)
