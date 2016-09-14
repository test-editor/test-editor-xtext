package org.testeditor.rcp4.createprojects

import org.testeditor.rcp4.*

# CreateSwingDemoAndRunTest

// given
config TestEditorConfig

// when
* Open "Test-Editor Project" wizard

	Component: ProjectExplorer
	- Execute menu item "New/Project..." in tree <ProjectTree>

	Component: NewProjectDialog
	- Select element "Test-Editor Project" in tree <ProjectType>
	- Click on <NextButton>

* Create project with "Swing fixture"

	Component: NewProjectDialog
	- Type "swingdemo" into <ProjectName>
	- Click on <NextButton>
	- Select value "Maven" in combo box <BuildTool>
	- Select element "Swing Fixture" in list <AvailableFixturesList>
	- Click on <AddFixtureButton>
	- Check <GenerateWithExamples>
	- Click on <FinishButton>
	- Wait until dialog with title "Progress Information" is closed

	Component: TestEditorServices
	- valid = Check if "swingdemo" is a valid testproject
	- assert valid = "true"

* Run "GreetingTest"

	Component: ProjectExplorer
	- Wait "2" seconds
	- Select element "swingdemo/Tests/swingdemo/GreetingTest.tcl" in tree <ProjectTree>
	- Execute menu item "Run test" in tree <ProjectTree>
	- Wait at most "20" seconds until dialog with title "Progress Information" is closed

// then
* Verify test execution result

	Component: HauptFenster
	- Is view <JUnitView> visible
	// TODO verify the contents of the view (test should be green)
