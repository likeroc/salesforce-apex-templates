salesforce-apex-templates
=========================

APEX Templates provide a simple template engine, similar to the standard Salesforce mail merge one. Its aim is to generate messages and emails directly from APEX, for provided SObjects or maps of values.

Basic usage
-----------

The below snippet demonstrates the most basic usage of APEX Templates:

```javascript
Case someCase = new Case(
  Subject = 'Test Case'
);

// The below will return 'A message for Test Case.'
new Template(
  'A message for {!Case.Subject}.'
).evaluate(someCase);
```


```javascript
Case someCase = new Case(Subject = 'Test Case2333', Description = 'dsc text');
//CaseEmailTemplete is a text email templete,
//which content is "Subject is {!Case.Subject};Description is : {!Case.Description} ."
//The below wiil return "Subject is Test Case2333;Description is : dsc text ."
String msg = Template.fromEmailTemplate('CaseEmailTemplete').evaluate(someCase);
```
