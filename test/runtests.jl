using DatadogProfileUploader

function myfunc()
  A = rand(2000, 200, 400)
  sort(A, dims=3)
end

config = DatadogProfileUploader.DDConfig("localhost", 8126, "petesrelmacbook.taila7a54.ts.net")

DatadogProfileUploader.profile_and_upload(config, myfunc)
