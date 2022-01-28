module DatadogProfileUploader

import HTTP

struct DDConfig
    url::String
    api_key::String
end

struct Profile
    start::Datetime
    finish::Datetime
    proto_path::String
end

function upload(config::DDConfig, profile::Profile)
    # do HTTP request
    headers = [
        "DD-API-KEY" => config.api_key,
    ]
    body = HTTP.Form([
        "version" => "3",
        "start" => format(profile.start, RFC3339),
        "end" => format(profile.finish, RFC3339),
        # tags[]
        "data[my_prof]" => HTTP.Multipart(
            "pprof-data",
            open(Profile.proto_path), # proto
            "application/octet-stream"
        ),
    ])
    HTTP.post(config.url, headers, body)
end

end # module
