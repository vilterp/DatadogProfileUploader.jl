module DatadogProfileUploader

import HTTP

using Dates
using Profile
using PProf

struct DDConfig
    host::String
    port::Int
    hostname::String
end

struct SerializedProfile
    start::DateTime
    finish::DateTime
    type::String # "heap" or "cpu"
    proto_path::String
end

function profile_and_upload(config, f)
    #Profile.clear()
    start = now()
    println("taking profile")
    # Profile.@profile f()
    println("done taking profile")
    finish = now()

    path = "profile.pb.gz" # TODO: temp file?
    #pprof(; web=false, out=path)
    # upload(config, SerializedProfile(start, finish, "cpu", path))
    upload(config, SerializedProfile(start, finish, "cpu", "../profile-julia-doctored.pb.gz"))
end

function upload(config::DDConfig, profile::SerializedProfile)
    @info "uploading"
    # do HTTP request
    headers = []
    name = "$(profile.type).pprof"
    parts = Pair{String,Any}[
        "version" => "3",
        "family" => "go",
        "start" => Dates.format(profile.start, ISODateTimeFormat),
        "end" => Dates.format(profile.finish, ISODateTimeFormat),
        "tags[]" => "host:$(config.hostname)",
        "tags[]" => "runtime:go",
        "tags[]" => "env:example",
        "tags[]" => "service:julia-test", # TODO: parameterize
        "tags[]" => "version:1.0", # TODO: parameterize
        # other stuff
        "data[metrics.json]" => HTTP.Multipart(
            "pprof-data",
            IOBuffer("""[["go_alloc_bytes_per_sec",637031112.2133334],["go_allocs_per_sec",69.76],["go_frees_per_sec",37.10666666666667],["go_heap_growth_bytes_per_sec",9128779.946666667],["go_gcs_per_sec",1.7066666666666668],["go_gc_pause_time",0.0002923213237688478],["go_max_gc_pause_time",8196327]]"""),
            "application/octet-stream",
        ),
        "data[$(name)]" => HTTP.Multipart(
            "pprof-data",
            open(profile.proto_path), # proto
            "application/octet-stream"
        ),
    ]
    println(parts)
    body = HTTP.Form(parts)
    url = "http://localhost:8126/profiling/v1/input"
    println("posting to $url")
    resp = HTTP.post(url, headers, body)
    println("got response ", resp)
end

end # module
