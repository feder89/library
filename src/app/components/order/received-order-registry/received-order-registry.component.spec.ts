import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { ReceivedOrderRegistryComponent } from './received-order-registry.component';

describe('ReceivedOrderRegistryComponent', () => {
  let component: ReceivedOrderRegistryComponent;
  let fixture: ComponentFixture<ReceivedOrderRegistryComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ ReceivedOrderRegistryComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(ReceivedOrderRegistryComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
