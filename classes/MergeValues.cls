/**
 * @author Andrzej Chodor
 */
public with sharing class MergeValues {
    private static Map<String, Schema.SObjectType> globalDescribe;

    private static Map<String, Map<String, Schema.SObjectField>> fieldDescribes;

    private Map<String, Object> values = new Map<String, Object>();

    private Map<String, Set<String>> registeredFields = new Map<String, Set<String>>();

    public MergeValues() {
    }

    /**
     * 合并值
     * @param  values     [description]
     */
    public MergeValues(Map<String,Object> values) {
        this();
        putAll(values);
    }

    public void put(String key, Object o) {
        values.put(key, o);
    }

    /**
     * SObject的Name添加到Map<String,Object>集合里
     * @param  o          SObject
     */
    public void put(SObject o) {
        String objectName = o.getSObjectType().getDescribe().getName();
        values.put(objectName, o);
    }

    public void putSObject(String sobjectTypeName, Id sobjectId) {
        if(!registeredFields.containsKey(sobjectTypeName)) {
            return;
        }
    
        String query =
            'SELECT ' + String.join(new List<String>(registeredFields.get(sobjectTypeName)), ',')
            + ' FROM ' + sobjectTypeName
            + ' WHERE id = :sobjectId';

        SObject[] results = Database.query(query);
        if(!results.isEmpty()) {
            values.put(sobjectTypeName, results[0]);
        }
    }

    public void putAll(Map<String, Object> topLevelValues) {
        values.putAll(topLevelValues);
    }

    /**
     * 表达式：SObject.Field。 通过表达式获取该变量值
     * @param  path       String。表达式，例如：Case.Subject
     * @return            Object。表达式对应的值
     */
    public Object get(String path) {

        String[] atoms = path.split('\\s*\\.\\s*');//通过'.'来截取字符串

        Object currentValue = values;
        for(Integer i = 0, size = atoms.size(); i < size; i++) {
            currentValue = getProperty(currentValue, atoms[i], i < size - 1);
        }
        return currentValue;
    }

    public void registerFieldSecurely(String path) {
        if(globalDescribe == null) {
            globalDescribe = Schema.getGlobalDescribe();
            fieldDescribes = new Map<String, Map<String, Schema.SObjectField>>();
        }

        String[] atoms = path.split('\\s*\\.\\s*');
        if(atoms.size() != 2) {
            return;
        }

        if(!registeredFields.containsKey(atoms[0])) {
            Schema.SObjectType objectType = globalDescribe.get(atoms[0]);
            if(objectType == null || !objectType.getDescribe().isAccessible()) {
                return;
            }

            registeredFields.put(atoms[0], new Set<String>{'Id'});
            fieldDescribes.put(atoms[0], objectType.getDescribe().fields.getMap());
        }

        Set<String> objectRegisteredFields = registeredFields.get(atoms[0]);
        if(!objectRegisteredFields.contains(atoms[1])) {
            Schema.SObjectField field = fieldDescribes.get(atoms[0]).get(atoms[1]);
            if(field != null && field.getDescribe().isAccessible()) {
                objectRegisteredFields.add(atoms[1]);
            }
        }
    }

    /**
     * 获取property的值
     * @param  o               Object
     * @param  property        String. 对象或者字段的API Name
     * @param  isInnerProperty Boolean. 
     * @return                 对象或者字段的实例
     */
    private static Object getProperty(Object o, String property, Boolean isInnerProperty) {

        if(o == null) {
            return null;
        }
    
        if(o instanceof Map<String, Object>) {
            return ((Map<String, Object>)o).get(property);
        }

        if(o instanceof SObject) {
            if(isInnerProperty) {
                return ((SObject)o).getSObject(property);//SObject.getSObject(String field). 返回该字段的值
            }
            return ((SObject)o).get(property);//
        }

        return null;
    }
}
