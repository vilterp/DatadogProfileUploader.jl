using DatadogProfileUploader

function myfunc()
  A = rand(2000, 200, 400)
  sort(A, dims=3)
end

config = DatadogProfileUploader.DDConfig("localhost", 8126, "Petes-Relational-Macbook.local", ENV["DD_API_KEY"])

DatadogProfileUploader.profile_and_upload(config, myfunc)
