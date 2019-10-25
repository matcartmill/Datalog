Pod::Spec.new do |spec|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  spec.name = 'Datalog'
  spec.version = '0.3.0'
  spec.homepage = 'https://github.com/MatCartmill/Datalog'
  spec.summary = 'An open-source iOS framework for HTTP(S) logging with Datadog. Written in Swift.'
  spec.description = <<-DESC
                      An open-source iOS framework for HTTP(S) logging with Datadog.
                      Written in Swift.
                     DESC

  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  spec.license = 'MIT'

  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  spec.author = { 'Mathew Cartmill' => 'mat.cartmill@gmail.com' }
  spec.social_media_url = 'https://twitter.com/matcartmill'

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  spec.platform = :ios, '11.0'
  spec.swift_version = '5.0'

  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  spec.source = { git: "#{spec.homepage}.git", tag: spec.version }

  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  spec.source_files = 'Datalog/**/*.swift'

  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  spec.framework = 'XCTest'

  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  spec.requires_arc = true

end
