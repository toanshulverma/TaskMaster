/*

Controller for entier TaskMaster application

Purpose of this class to is to demonstrate VF-Apex capability to render mobile forms using jQueryMobile and prest inttuitive user interface

*/

public with sharing class TaskListController
{
	public String SignatureImage {get; set;}
	public transient List<Task> CurrentWeekTasks {get; set;}
	public transient List<Task> NextWeekTasks {get; set;}
	public transient List<Task> LaterTasks {get; set;}
	
	public Task CurrentTask {get; set;}
	
	public TaskListController()
	{
		SignatureImage = '';
		
		String taskId = Apexpages.currentPage().getParameters().get('id');
		
		//check if a task is selected
		if(taskId != null && taskId != '')
		{
			//task is selected; load task
			CurrentTask = Database.query(getTaskQuery(taskId));
		}
		else
		{
			//task is not selected; load all open tasks
			loadTasks();
		}
	}
	
	//returns all fields which are to be displayed in Mobile page
	public List<Schema.FieldSetMember> getTaskFields()
	{
		return SObjectType.Task.FieldSets.MobileView.getFields(); 
	}
	
	//retrieves task information based on fields selected in Fieldset named "MobileView"
	private String getTaskQuery(String taskId)
	{
		String query = 'SELECT ';
		query += 'Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingPostalCode, Account.BillingCountry, ';
		for(Schema.FieldSetMember f : getTaskFields()) {
			query += ' ' + f.getFieldPath() + ', ';
		}
		query += ' Id, CustomerSignatureRequired__c FROM Task where id=\'' + taskId + '\'';
		return query;
	}

	//Load tasks
	public void loadTasks()
	{
		//fetch tasks
		CurrentWeekTasks = new List<Task>();
		NextWeekTasks = new List<Task>();
		LaterTasks = new List<Task>();		
		
		//retrieve current week
		Integer currentWeek = getWeek(System.now());
		
		//fetch tasks and group them in lists
		for(Task task :[select id, Subject, ActivityDate, CustomerSignatureRequired__c from Task where IsClosed = false order by ActivityDate])
		{
			Integer taskWeek = getWeek(task.ActivityDate);
			
			if(currentWeek == taskWeek)
			{
				//task is for current week
				CurrentWeekTasks.add(task);
			}
			else if(currentWeek + 1 == taskWeek)
			{
				//task is for next week
				NextWeekTasks.add(task);
			}
			else
			{
				//task is for for future
				LaterTasks.add(task);
			}
		}
	}
	
	//returns week number of provided datetime value
	private Integer getWeek(DateTime dt)
	{
		return Integer.valueOf(System.now().format('w'));
	}
	
	//event handler to close task button
	public void closeTask()
	{
		System.savepoint sp = Database.setSavePoint();
		try
		{
			//create client signature attachment image
			Attachment newAttachment = new Attachment();
			newAttachment.ParentId = CurrentTask.id;
			String imageBody = SignatureImage.replaceAll('data:image/png;base64,', '');
			newAttachment.body = Encodingutil.base64Decode(imageBody);
			newAttachment.name = 'ClientSignature.png';
			insert newAttachment;
			
			//close task
			CurrentTask.Status = 'Completed';
			update CurrentTask;
		}
		catch(Exception ex)
		{
			// for demo do nothing; let page redirect user to main page;
			Database.rollback(sp);
		}		
	}
}