import json
import os
import unittest
from subprocess import check_call, check_output

cwd = os.getcwd()


class TestCreateTaskdef(unittest.TestCase):

    def setUp(self):
        check_call(['terraform', 'get', 'test/infra'])
        check_call(['terraform', 'init', 'test/infra'])

    def get_output_json(self):
        return json.loads(check_output([
            'terraform',
            'show',
            '-json',
            'plan.out'
        ]).decode('utf-8'))

    def get_resource_changes(self):
        output = self.get_output_json()
        r = output.get('resource_changes')
        print(json.dumps(r, indent=2))
        return r

    def assert_resource_changes_action(self, resource_changes, action, length):
        resource_changes_create = [
            rc for rc in resource_changes
            if rc.get('change').get('actions') == [action]
        ]
        assert len(resource_changes_create) == length

    def assert_resource_changes(self, testname, resource_changes):
        with open(f'test/files/{testname}.json', 'r') as f:
            data = json.load(f)

            assert data == resource_changes

    def test_all_resources_to_be_created(self):
        # Given When
        check_call([
            'terraform',
            'plan',
            '-out=plan.out',
            '-no-color',
            'test/infra'
        ])

        resource_changes = self.get_resource_changes()

        # Then
        assert len(resource_changes) == 4
        self.assert_resource_changes_action(resource_changes, 'create', 4)
        self.assert_resource_changes('create_lambda', resource_changes)

    def test_all_resources_to_be_created_for_container_lambda(self):
        # Given When
        check_call([
            'terraform',
            'plan',
            '-out=plan.out',
            '-no-color',
            'test/infra_container'
        ])

        resource_changes = self.get_resource_changes()

        # Then
        assert len(resource_changes) == 4
        self.assert_resource_changes_action(resource_changes, 'create', 4)
        self.assert_resource_changes('create_lambda_container', resource_changes)


    def test_create_lambda_in_vpc(self):
        # Given When
        check_call([
            'terraform',
            'plan',
            '-out=plan.out',
            '-var', 'subnet_ids=[1,2,3]',
            '-var', 'security_group_ids=[4]',
            '-no-color',
            'test/infra'
        ])

        resource_changes = self.get_resource_changes()

        # Then
        assert len(resource_changes) == 5
        self.assert_resource_changes_action(resource_changes, 'create', 5)
        self.assert_resource_changes('create_lambda_in_vpc', resource_changes)

    def test_create_lambda_with_reserved_concurrent_executions(self):
        # Given When
        check_call([
            'terraform',
            'plan',
            '-out=plan.out',
            '-var', 'reserved_concurrent_executions=3',
            '-no-color',
            'test/infra'
        ])

        resource_changes = self.get_resource_changes()
        # Then
        assert len(resource_changes) == 4
        self.assert_resource_changes_action(resource_changes, 'create', 4)
        self.assert_resource_changes(
            'create_lambda_with_reserved_concurrent_executions',
            resource_changes
        )

    def test_create_lambda_with_tags(self):
        # Given When
        check_call([
            'terraform',
            'plan',
            '-out=plan.out',
            '-var', 'tags={"component":"test-component","env":"test"}',
            '-no-color',
            'test/infra'
        ])

        resource_changes = self.get_resource_changes()

        # Then
        assert len(resource_changes) == 4
        self.assert_resource_changes_action(resource_changes, 'create', 4)
        self.assert_resource_changes(
            'create_lambda_with_tags',
            resource_changes
        )

    def test_create_lambda_with_layers(self):
        # Given When
        check_call([
            'terraform',
            'plan',
            '-out=plan.out',
            '-var', 'layers=["arn:aws:lambda:eu-west-1:aws:r1"]',
            '-no-color',
            'test/infra'
        ])

        resource_changes = self.get_resource_changes()

        # Then
        assert len(resource_changes) == 4
        self.assert_resource_changes_action(resource_changes, 'create', 4)
        self.assert_resource_changes(
            'create_lambda_with_layers',
            resource_changes
        )    

