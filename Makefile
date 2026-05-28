.PHONY: build test run app clean

build:
	swift build

test:
	swift test

run:
	swift run Slip

app: build
	rm -rf .build/Slip.app
	mkdir -p .build/Slip.app/Contents/MacOS
	mkdir -p .build/Slip.app/Contents/Resources
	cp .build/debug/Slip .build/Slip.app/Contents/MacOS/Slip
	/usr/libexec/PlistBuddy -c "Clear dict" .build/Slip.app/Contents/Info.plist
	/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string Slip" .build/Slip.app/Contents/Info.plist
	/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string app.slip.mvp" .build/Slip.app/Contents/Info.plist
	/usr/libexec/PlistBuddy -c "Add :CFBundleName string Slip" .build/Slip.app/Contents/Info.plist
	/usr/libexec/PlistBuddy -c "Add :CFBundlePackageType string APPL" .build/Slip.app/Contents/Info.plist
	/usr/libexec/PlistBuddy -c "Add :LSMinimumSystemVersion string 14.0" .build/Slip.app/Contents/Info.plist
	/usr/libexec/PlistBuddy -c "Add :LSUIElement bool true" .build/Slip.app/Contents/Info.plist

clean:
	rm -rf .build
